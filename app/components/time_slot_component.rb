# frozen_string_literal: true

# A single hour within a day's timeline: the time label, any meetups booked into
# that hour, and a "request slot" affordance for the locations still open.
class TimeSlotComponent < ApplicationComponent
  def initialize(scheduling_day:, start_time:, meetups:, active_location_count:, blocked_location_ids: [], viewer: nil, show_open_slots: true)
    @scheduling_day = scheduling_day
    @start_time = start_time
    @meetups = meetups
    @active_location_count = active_location_count
    @blocked_location_ids = blocked_location_ids || []
    @viewer = viewer
    @show_open_slots = show_open_slots
  end

  private

  attr_reader :scheduling_day, :start_time, :meetups, :active_location_count, :blocked_location_ids, :viewer, :show_open_slots

  def time_label
    start_time.strftime("%-l:%M %p")
  end

  # Packs day + start time for the meetup form's day/time picker so "Request
  # slot" lands on this exact hour. Mirrors MeetupsHelper#meetup_slot_groups.
  def slot_param
    "#{scheduling_day.id}:#{start_time.to_i}"
  end

  # 24-hour integer used as a data hook so the client can position the
  # current-time marker against this row.
  def hour_24
    start_time.hour
  end

  # Locations still bookable this hour. Unioning booked and blocked location
  # ids avoids double-counting a location that was booked before its hour was
  # blocked.
  def open_slots
    unavailable = (meetups.map(&:location_id) | blocked_location_ids).size
    [ active_location_count - unavailable, 0 ].max
  end

  # A timeslot that has already started can't be claimed.
  def past?
    start_time.past?
  end
end
