# frozen_string_literal: true

module Stafftools
  class SchedulingDaysController < ApplicationController
    before_action :require_current_event
    before_action :set_scheduling_day, only: %i[edit update destroy]

    def index
      @scheduling_days = current_event.scheduling_days.order(:date)
    end

    def new
      @scheduling_day = current_event.scheduling_days.new
    end

    def create
      @scheduling_day = current_event.scheduling_days.new(scheduling_day_params)

      if @scheduling_day.save
        redirect_to stafftools_scheduling_days_path, notice: "Meetup day added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @scheduling_day.update(scheduling_day_params)
        redirect_to stafftools_scheduling_days_path, notice: "Meetup day updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @scheduling_day.destroy
        redirect_to stafftools_scheduling_days_path, notice: "Meetup day removed."
      else
        redirect_to stafftools_scheduling_days_path,
          alert: "Can't remove a day that still has meetups scheduled."
      end
    end

    private

    def set_scheduling_day
      @scheduling_day = current_event.scheduling_days.find(params[:id])
    end

    def scheduling_day_params
      params.require(:scheduling_day).permit(:date, :start_time, :end_time)
    end
  end
end
