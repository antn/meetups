# frozen_string_literal: true

module Stafftools
  class LocationsController < ApplicationController
    before_action :require_current_event
    before_action :set_location, only: %i[edit update destroy]

    def index
      @locations = current_event.locations.order(:name)
    end

    def new
      @location = current_event.locations.new
    end

    def create
      @location = current_event.locations.new(location_params)

      if @location.save
        sync_blocked_hours
        redirect_to stafftools_locations_path, notice: "Location added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @location.update(location_params)
        sync_blocked_hours
        redirect_to stafftools_locations_path, notice: "Location updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @location.destroy
        redirect_to stafftools_locations_path, notice: "Location removed."
      else
        redirect_to stafftools_locations_path,
          alert: "Can't remove a location that still has meetups. Deactivate it instead."
      end
    end

    private

    def set_location
      @location = current_event.locations.find(params[:id])
    end

    def location_params
      params.require(:location).permit(:name, :description, :active, :map_image)
    end

    # Reconcile blocked hours from the form's availability grid: every hour of
    # every scheduling day whose chip wasn't submitted as available becomes
    # blocked. Only hours that currently exist on a day are ever written, so
    # the grid is the full source of truth. Skipped entirely when the grid
    # wasn't rendered (its hidden marker field is absent).
    def sync_blocked_hours
      return unless params[:location]&.key?(:available_hour_keys)

      available = Array(params[:location][:available_hour_keys]).reject(&:blank?).to_set
      existing = @location.blocked_hours.index_by { |blocked| "#{blocked.scheduling_day_id}:#{blocked.hour}" }

      current_event.scheduling_days.find_each do |day|
        day.valid_start_times.each do |start_time|
          key = "#{day.id}:#{start_time.hour}"
          if available.include?(key)
            existing[key]&.destroy
          elsif existing[key].nil?
            @location.blocked_hours.create!(scheduling_day: day, hour: start_time.hour)
          end
        end
      end
    end
  end
end
