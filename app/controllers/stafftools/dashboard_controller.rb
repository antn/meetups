# frozen_string_literal: true

module Stafftools
  class DashboardController < ApplicationController
    def index
      return if current_event.nil?

      @scheduling_day_count = current_event.scheduling_days.count
      @location_count = current_event.locations.count
      @tag_count = current_event.tags.count
      @pending_count = current_event.meetups.pending.count
    end
  end
end
