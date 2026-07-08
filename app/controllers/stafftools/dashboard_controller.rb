# frozen_string_literal: true

module Stafftools
  class DashboardController < ApplicationController
    def index
      return if current_event.nil?

      @scheduling_day_count = current_event.scheduling_days.count
      @location_count = current_event.locations.count
      @tag_count = current_event.tags.count
      @pending_count = current_event.meetups.pending.count

      @top_meetups = current_event.meetups.visible
        .left_joins(:attendances)
        .select("meetups.*, COUNT(attendances.id) AS rsvp_count")
        .group("meetups.id")
        .having("COUNT(attendances.id) > 0")
        .order("rsvp_count DESC, meetups.starts_at ASC")
        .limit(10)
        .preload(:user, :location)
    end
  end
end
