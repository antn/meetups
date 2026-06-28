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
        redirect_to stafftools_locations_path, notice: "Location added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @location.update(location_params)
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
      params.require(:location).permit(:name, :description, :active)
    end
  end
end
