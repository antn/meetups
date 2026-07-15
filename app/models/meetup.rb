# frozen_string_literal: true

class Meetup < ApplicationRecord
  # Raised when a merge's preconditions aren't met (see #merge_into!).
  class MergeError < StandardError; end

  # Fixed meetup length. A meetup runs starts_at .. starts_at + DURATION.
  DURATION = 1.hour

  # How long before a meetup starts we remind its host and attendees.
  REMINDER_LEAD = 1.hour

  belongs_to :event
  belongs_to :user
  belongs_to :location
  belongs_to :scheduling_day
  belongs_to :reviewed_by, class_name: "User", optional: true
  belongs_to :merged_into, class_name: "Meetup", optional: true

  has_many :meetup_tags, dependent: :destroy
  has_many :tags, through: :meetup_tags
  has_many :attendances, dependent: :destroy
  has_many :attendees, through: :attendances, source: :user

  # NOTE: these integer values are relied on by the partial unique index
  # `index_meetups_unique_active_slot` (where "status NOT IN (2, 3)"). Do not reorder.
  enum :status, { pending: 0, approved: 1, rejected: 2, cancelled: 3 }, default: :pending

  # Keep everyone informed through the moderation lifecycle: the submitter on
  # every status change, plus RSVP'd attendees when a meetup is cancelled.
  after_create_commit :send_meetup_requested_notification
  after_update_commit :send_status_change_notification
  # If the host reschedules, any reminder we already sent pointed at the old
  # time, so arm a fresh one for the new start.
  after_update_commit :rearm_reminder_on_reschedule

  # Statuses that release the slot and hide the meetup from listings: a rejected
  # meetup (by an admin) or a cancelled one (by the submitter).
  INACTIVE_STATUSES = %i[rejected cancelled].freeze

  validates :title, presence: true
  validates :description, presence: true, length: { minimum: 15, maximum: 280 }
  validates :starts_at, presence: true
  validates :rejection_reason, presence: true, if: :rejected?
  validate :starts_at_in_day_window
  validate :starts_at_not_in_past, on: :create
  validate :associations_share_event
  validate :location_is_active, on: :create
  validate :requires_a_tag
  validate :slot_available
  validate :slot_not_blocked

  # Rejected/cancelled meetups are never shown in listings; they also free the slot.
  scope :visible, -> { where.not(status: INACTIVE_STATUSES) }
  scope :occupying, -> { where.not(status: INACTIVE_STATUSES) }
  scope :for_day, ->(day) { where(scheduling_day: day) }

  # Approved meetups whose start is within REMINDER_LEAD from now and that
  # haven't been reminded yet. Bounding the low end at `from` excludes meetups
  # that have already started (e.g. one approved after it began).
  scope :due_for_reminder, ->(from = Time.current) {
    approved.where(reminder_sent_at: nil, starts_at: from..(from + REMINDER_LEAD))
  }

  # Meetups carrying any of the given tag public_ids (OR). A subquery keeps it
  # free of joins/duplicates so it composes cleanly with includes/.or.
  scope :tagged_with, ->(tag_public_ids) {
    where(id: MeetupTag.joins(:tag).where(tags: { public_id: tag_public_ids }).select(:meetup_id))
  }

  # Meetups a given viewer is allowed to see in a listing: approved ones are
  # public; a viewer also sees their own pending submissions; admins see all
  # non-rejected meetups.
  scope :listable_for, ->(viewer) {
    if viewer&.site_admin?
      visible
    elsif viewer
      where(status: :approved).or(where(status: :pending, user_id: viewer.id))
    else
      where(status: :approved)
    end
  }

  def ends_at
    return if starts_at.blank?

    starts_at + DURATION
  end

  # Human-readable start date in the event's timezone, e.g. "Friday, May 2, 2025".
  def formatted_start_date
    return if starts_at.blank?

    starts_at.in_time_zone(event.tz).strftime("%A, %B %-d, %Y")
  end

  # Human-readable time range in the event's timezone, e.g. "1 PM - 2 PM".
  def formatted_duration
    return if starts_at.blank?

    "#{starts_at.in_time_zone(event.tz).strftime("%-l %p")} - #{ends_at.in_time_zone(event.tz).strftime("%-l %p")}"
  end

  # One-line summary for social cards (og:description / twitter:description),
  # e.g. "📅 Friday, May 2 · 1 PM - 2 PM · 📍 Artist Alley — Come sing with us!"
  def social_description
    return description if starts_at.blank?

    "📅 #{starts_at.in_time_zone(event.tz).strftime("%A, %b %-d")} · #{formatted_duration} · 📍 #{location.name} — #{description}"
  end

  # Whether a viewer may see this meetup's details (beyond its location/timeslot
  # hold). Approved meetups are public; pending meetups are visible only to the
  # submitter and admins; rejected meetups are visible to no one.
  def visible_to?(viewer)
    return true if approved?
    return false if rejected? || cancelled?

    # pending
    viewer.present? && (viewer.id == user_id || viewer.site_admin?)
  end

  # Who may edit this submission: its submitter or any admin, while it's still
  # live (pending or approved). Rejected/cancelled meetups are read-only.
  def editable_by?(user)
    return false if user.nil?
    return false unless pending? || approved?

    user.site_admin? || user.id == user_id
  end

  def approve!(by:)
    transaction do
      update!(status: :approved, reviewed_by: by, reviewed_at: Time.current, rejection_reason: nil)
    end
  end

  def reject!(by:, reason:)
    transaction do
      update!(status: :rejected, reviewed_by: by, reviewed_at: Time.current, rejection_reason: reason)
    end
  end

  # Cancellation is not an admin review, so it leaves the reviewed_by/reviewed_at
  # metadata untouched. Frees the slot and notifies the host and attendees.
  def cancel!
    update!(status: :cancelled)
  end

  # Fold this meetup into `target`: move RSVPs over (skipping people already
  # going to the target), cancel this meetup without the usual cancellation
  # email, and instead tell everyone affected where their meetup went.
  def merge_into!(target)
    raise MergeError, "Choose a meetup to merge into." if target.nil?
    raise MergeError, "A meetup can't be merged into itself." if target.id == id
    raise MergeError, "Both meetups must belong to the same event." if target.event_id != event_id
    raise MergeError, "The target meetup must be approved." unless target.approved?
    raise MergeError, "This meetup was already merged." if merged_into_id.present?
    raise MergeError, "Only pending or approved meetups can be merged." unless pending? || approved?

    # Snapshot before moving RSVPs, or the source's attendee list is empty by
    # send time.
    recipients = reminder_recipients

    transaction do
      # Drop RSVPs that would collide with the target's unique (user, meetup)
      # index, then move the rest wholesale.
      attendances.where(user_id: target.attendances.select(:user_id)).destroy_all
      attendances.update_all(meetup_id: target.id, updated_at: Time.current)

      # Setting merged_into alongside the status suppresses the standard
      # cancellation email (see send_status_change_notification).
      update!(status: :cancelled, merged_into: target)
    end

    recipients.each do |recipient|
      MeetupsMailer.meetup_merged(source: self, target: target, user: recipient).deliver_later
    end
  end

  # Undo a review decision, putting the meetup back in the pending queue and
  # clearing the review metadata so it reads as untouched.
  def revert_to_pending!
    transaction do
      update!(status: :pending, reviewed_by: nil, reviewed_at: nil, rejection_reason: nil)
    end
  end

  # Everyone who should hear that this meetup is about to start: its host plus
  # anyone who RSVP'd. Deduped (the host may also have RSVP'd).
  def reminder_recipients
    (attendees.to_a + [ user ]).uniq
  end

  # Send the "starting soon" reminder to every recipient, but only claim the
  # send once: the conditional UPDATE stamps reminder_sent_at atomically so two
  # overlapping sweeps can't both fire. Returns true if this call did the send.
  def deliver_start_reminder!
    claimed = self.class.where(id: id, reminder_sent_at: nil).update_all(reminder_sent_at: Time.current)
    return false unless claimed == 1

    reminder_recipients.each do |recipient|
      MeetupsMailer.meetup_reminder(meetup: self, user: recipient).deliver_later
    end
    true
  end

  private

  # A start-time change invalidates a reminder we've already sent. Clear the
  # stamp (via update_column to avoid re-triggering commit callbacks) so the
  # sweep re-arms it for the new time.
  def rearm_reminder_on_reschedule
    return unless saved_change_to_starts_at?
    return if reminder_sent_at.nil?

    update_column(:reminder_sent_at, nil)
  end

  def send_meetup_requested_notification
    MeetupsMailer.meetup_requested(meetup: self).deliver_later
  end

  def send_status_change_notification
    return unless saved_change_to_status?

    if approved?
      MeetupsMailer.meetup_approved(meetup: self).deliver_later
    elsif rejected?
      MeetupsMailer.meetup_rejected(meetup: self).deliver_later
    elsif cancelled?
      # A merge cancels the source but sends its own "merged" email instead.
      return if merged_into_id.present?

      # Cancellation affects everyone who was going, not just the host.
      reminder_recipients.each do |recipient|
        MeetupsMailer.meetup_cancelled(meetup: self, user: recipient).deliver_later
      end
    elsif pending?
      # The only way to reach pending on update is a moderator reverting an
      # earlier decision; on create this callback doesn't fire.
      MeetupsMailer.meetup_reverted(meetup: self).deliver_later
    end
  end

  def starts_at_in_day_window
    return if starts_at.blank? || scheduling_day.blank?

    unless scheduling_day.valid_start_times.any? { |time| time == starts_at }
      errors.add(:starts_at, "must be an available hour within the scheduling day")
    end
  end

  # You can't claim a timeslot that has already started/passed.
  def starts_at_not_in_past
    return if starts_at.blank?

    errors.add(:starts_at, "has already passed") if starts_at.past?
  end

  def associations_share_event
    [ location, scheduling_day ].each do |record|
      next if record.blank? || event_id.blank?

      if record.event_id != event_id
        errors.add(:base, "#{record.class.name.downcase} must belong to the same event")
      end
    end
  end

  def location_is_active
    return if location.blank?

    errors.add(:location, "is not available for booking") unless location.active?
  end

  def requires_a_tag
    if meetup_tags.reject(&:marked_for_destruction?).empty?
      errors.add(:tags, "must include at least one tag")
    end
  end

  def slot_available
    return if location_id.blank? || starts_at.blank?

    conflict = Meetup.where(location_id: location_id, starts_at: starts_at).where.not(status: INACTIVE_STATUSES)
    conflict = conflict.where.not(id: id) if persisted?

    errors.add(:base, "That location is already booked for this time") if conflict.exists?
  end

  # Blocked hours only prevent taking a slot, not keeping one: a meetup booked
  # before the block was added must still be approvable/cancellable, so this
  # only runs when the slot itself is being chosen or moved.
  def slot_not_blocked
    return if location.blank? || scheduling_day.blank? || starts_at.blank?
    return unless new_record? || will_save_change_to_starts_at? || will_save_change_to_location_id?

    if location.blocked_at?(scheduling_day, starts_at)
      errors.add(:base, "That location is not available at this time")
    end
  end
end
