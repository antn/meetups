# frozen_string_literal: true

class SchedulesController < ApplicationController
  before_action :require_authentication

  def show
    @event = Event.current
    return if @event.nil?

    @tags = @event.tags.order(:name)
    @selected_tags = Array(params[:tags]).reject(&:blank?)

    attended_ids = current_user.attendances.pluck(:meetup_id)
    base = @event.meetups.visible
      .where(user_id: current_user.id)
      .or(@event.meetups.visible.where(id: attended_ids))

    # Keep the filter chips visible (and the schedule layout) even when a filter
    # empties the result; only fall back to the blank slate when the user has
    # nothing at all.
    @has_meetups = base.exists?
    @meetups = @selected_tags.any? ? base.tagged_with(@selected_tags) : base
  end
end
