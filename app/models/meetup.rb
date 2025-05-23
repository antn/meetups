# frozen_string_literal: true

class Meetup < ApplicationRecord
  OFFKAI_TIMEZONE = "Pacific Time (US & Canada)"

  belongs_to :user
  belongs_to :meetup_area, optional: true
  belongs_to :meetup_day, optional: true

  validates :name, presence: true, length: { minimum: 3, maximum: 50 }
  validates :description, presence: true, length: { minimum: 15, maximum: 280 }
  validates :starts_at, :ends_at, presence: true
  validate :no_duplicate_meetup_in_area, on: :create
  validate :validate_whole_hours
  validate :validate_ends_after_starts

  enum :state, [:pending, :approved, :rejected]

  after_create_commit :send_meetup_requested_notification
  after_update_commit :send_state_change_notification

  def adminable_by?(actor)
    return false unless actor.present?
    return true if actor.site_admin?
    actor == user
  end

  def formatted_start_date
    starts_at.in_time_zone(OFFKAI_TIMEZONE).strftime("%A, %B %-d, %Y")
  end

  def formatted_duration
    "#{starts_at.in_time_zone(OFFKAI_TIMEZONE).strftime("%-l %p")} - #{ends_at.in_time_zone(OFFKAI_TIMEZONE).strftime("%-l %p")}"
  end

  private

  def send_state_change_notification
    if saved_change_to_state?
      if state == "approved"
        MeetupsMailer.meetup_approved(meetup: self).deliver_now
      elsif state == "rejected"
        MeetupsMailer.meetup_rejected(meetup: self).deliver_now
      end
    end
  end

  def send_meetup_requested_notification
    MeetupsMailer.meetup_requested(meetup: self).deliver_now
  end

  def no_duplicate_meetup_in_area
    return if meetup_area_id.nil? || starts_at.nil? || ends_at.nil?

    conflict = Meetup.where(
      meetup_area_id: meetup_area_id,
      starts_at: starts_at,
      ends_at: ends_at
    ).where.not(state: :rejected).exists?

    if conflict
      errors.add(:starts_at, "A meetup already exists for this area and time slot.")
    end
  end

  def validate_whole_hours
    if starts_at.present? && starts_at.min != 0
      errors.add(:starts_at, "must be set to a whole hour (no minutes)")
    end

    if ends_at.present? && ends_at.min != 0
      errors.add(:ends_at, "must be set to a whole hour (no minutes)")
    end
  end

  def validate_ends_after_starts
    if starts_at.present? && ends_at.present? && ends_at <= starts_at
      errors.add(:ends_at, "must be after starts_at")
    end
  end
end
