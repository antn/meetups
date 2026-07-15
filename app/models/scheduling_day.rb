# frozen_string_literal: true

class SchedulingDay < ApplicationRecord
  belongs_to :event
  has_many :meetups, dependent: :restrict_with_error
  has_many :location_blocked_hours, dependent: :destroy

  validates :date, presence: true, uniqueness: { scope: :event_id }
  validates :start_time, :end_time, presence: true
  validate :end_after_start
  validate :times_on_the_hour

  # Absolute instants (in the event's timezone) at which a meetup may begin: one
  # per hour from start_time up to but excluding end_time. Closing-time
  # semantics -> the last meetup begins at end_time - 1h and finishes by end_time.
  def valid_start_times
    return [] if start_time.blank? || end_time.blank? || date.blank?

    zone = event.tz
    (start_time.hour...end_time.hour).map do |hour|
      zone.local(date.year, date.month, date.day, hour)
    end
  end

  def slot_count
    valid_start_times.size
  end

  private

  def end_after_start
    return if start_time.blank? || end_time.blank?

    errors.add(:end_time, "must be after the start time") if end_time <= start_time
  end

  def times_on_the_hour
    [ :start_time, :end_time ].each do |attr|
      value = public_send(attr)
      next if value.blank?

      errors.add(attr, "must be on the hour") unless value.min.zero? && value.sec.zero?
    end
  end
end
