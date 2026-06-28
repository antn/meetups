# frozen_string_literal: true

# The meetup schedule for an event: a day selector (tabs) plus, for each day, an
# hour-by-hour timeline of slots. Reads straight from the models — scheduling
# days define the hours, visible meetups fill the slots, and active locations
# determine how many openings remain. Day switching is handled client-side by
# the `day-tabs` Catalyst element (see app/javascript/components/day_tabs_element.js).
#
# Reused by "My schedule" with a filtered `meetups` set, `show_open_slots: false`
# (no booking affordance), and `collapse_empty: true` (hide empty hours/days).
class ScheduleComponent < ApplicationComponent
  def initialize(event:, viewer: nil, meetups: nil, show_open_slots: true, collapse_empty: false, selected_day: nil)
    @event = event
    @viewer = viewer
    @meetups = meetups
    @show_open_slots = show_open_slots
    @collapse_empty = collapse_empty
    @selected_day = selected_day
  end

  def render?
    event.present?
  end

  private

  attr_reader :event, :viewer, :show_open_slots, :collapse_empty, :selected_day

  def days
    @days ||= event.scheduling_days.order(:date).to_a
  end

  # Which day tab is open on load: an explicit `day` index (kept in the URL as
  # the viewer switches days, so tag-filter reloads preserve it), else today if
  # the event is running today, else the first day.
  def selected_index
    if selected_day.to_s.match?(/\A\d+\z/)
      index = selected_day.to_i
      return index if index.between?(0, days.size - 1)
    end

    today_index || 0
  end

  # Each day's bookable hours paired with the meetups occupying them. When
  # collapsing, hours with nothing scheduled are dropped (a day left with no
  # rows renders a blank slate instead — see ScheduleDayComponent).
  def slots_for(day)
    slots = day.valid_start_times.map do |start_time|
      { start_time: start_time, meetups: meetups_for(day, start_time) }
    end
    collapse_empty ? slots.select { |slot| slot[:meetups].any? } : slots
  end

  def meetups_for(day, start_time)
    meetups_by_slot[[ day.id, start_time.to_i ]] || []
  end

  # The slot-occupying meetups to display (defaults to every visible meetup for
  # the event), loaded once and grouped by [day, start-time] to avoid per-slot
  # queries. `:attendances` is preloaded so RSVP buttons don't N+1.
  def meetups_by_slot
    @meetups_by_slot ||= (@meetups || event.meetups.visible)
      .includes(:user, :location, :tags, :attendances)
      .group_by { |meetup| [ meetup.scheduling_day_id, meetup.starts_at.to_i ] }
  end

  def active_location_count
    @active_location_count ||= event.locations.active.count
  end

  # The day to render the "current time" marker on: the one whose date is today
  # in the event's timezone. Nil (no marker) when the event isn't running today.
  def today_index
    @today_index ||= days.index { |day| day.date == event.tz.today }
  end

  def tab_classes(active)
    base = "cursor-pointer rounded-full px-5 py-2 text-sm font-semibold transition"
    state = active ? "bg-brand-purple text-white shadow-sm" : "bg-gray-100 text-gray-600 hover:bg-gray-200"
    "#{base} #{state}"
  end
end
