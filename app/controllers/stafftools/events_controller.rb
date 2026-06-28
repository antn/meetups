# frozen_string_literal: true

module Stafftools
  # Events are the top-level container, so this controller is the one corner of
  # stafftools that doesn't depend on a current event existing.
  class EventsController < ApplicationController
    before_action :set_event, only: %i[edit update activate destroy]

    def index
      @events = Event.order(active: :desc, name: :asc)
    end

    def new
      @event = Event.new
    end

    def create
      @event = Event.new(event_params)

      if @event.save
        redirect_to stafftools_events_path, notice: "Event created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @event.update(event_params)
        redirect_to stafftools_events_path, notice: "Event updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # Make this the single active event (deactivating any other).
    def activate
      @event.activate!
      redirect_to stafftools_events_path, notice: "“#{@event.name}” is now the active event."
    end

    def destroy
      if @event.destroy
        redirect_to stafftools_events_path, notice: "Event deleted."
      else
        redirect_to stafftools_events_path,
          alert: "Can't delete an event that still has days, locations, tags, or meetups."
      end
    end

    private

    def set_event
      @event = Event.find(params[:id])
    end

    def event_params
      params.require(:event).permit(:name, :time_zone)
    end
  end
end
