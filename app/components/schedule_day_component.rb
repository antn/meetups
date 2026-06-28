# frozen_string_literal: true

# One day's timeline within the schedule: an ordered list of hour rows, wrapped
# in a `time-marker` element on "today" so the client can draw the current-time
# line across it.
class ScheduleDayComponent < ApplicationComponent
  def initialize(day:, slots:, active_location_count:, viewer: nil, today: false, show_open_slots: true)
    @day = day
    @slots = slots
    @active_location_count = active_location_count
    @viewer = viewer
    @today = today
    @show_open_slots = show_open_slots
  end

  private

  attr_reader :day, :slots, :active_location_count, :viewer, :today, :show_open_slots
end
