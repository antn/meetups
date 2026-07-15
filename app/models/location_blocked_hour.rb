# frozen_string_literal: true

# An hour of a scheduling day during which a location can't be booked. Blocking
# only prevents new bookings — meetups that already occupy the hour stay
# scheduled.
class LocationBlockedHour < ApplicationRecord
  belongs_to :location
  belongs_to :scheduling_day

  validates :hour,
    presence: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 24 },
    uniqueness: { scope: [ :location_id, :scheduling_day_id ] }
  validate :hour_within_day_window
  validate :location_and_day_share_event

  # The absolute instant (in the event's timezone) this block applies to.
  # Matches the corresponding entry of SchedulingDay#valid_start_times.
  def starts_at
    return if scheduling_day.blank? || hour.blank?

    date = scheduling_day.date
    scheduling_day.event.tz.local(date.year, date.month, date.day, hour)
  end

  private

  def hour_within_day_window
    return if hour.blank? || scheduling_day.blank?
    return if scheduling_day.start_time.blank? || scheduling_day.end_time.blank?

    unless (scheduling_day.start_time.hour...scheduling_day.end_time.hour).cover?(hour)
      errors.add(:hour, "must be within the scheduling day's hours")
    end
  end

  def location_and_day_share_event
    return if location.blank? || scheduling_day.blank?

    if location.event_id != scheduling_day.event_id
      errors.add(:base, "location and scheduling day must belong to the same event")
    end
  end
end
