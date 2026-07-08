# frozen_string_literal: true

class MeetupsController < ApplicationController
  before_action :require_authentication, only: %i[new create edit update cancel]
  before_action :require_current_event, only: %i[new create]
  before_action :require_accepting_meetups, only: %i[new create]
  before_action :set_editable_meetup, only: %i[edit update]
  before_action :set_cancellable_meetup, only: :cancel

  # The public schedule for the active event (the site's home page).
  def index
    @event = Event.current
    return if @event.nil?

    @tags = @event.tags.order(:name)
    @selected_tags = Array(params[:tags]).reject(&:blank?)
    @meetups = @event.meetups.visible
    @meetups = @meetups.tagged_with(@selected_tags) if @selected_tags.any?
  end

  def show
    @meetup = Meetup.includes(:attendances).find_by(public_id: params[:id])

    # Approved meetups are public; pending ones are visible only to their
    # submitter (and admins). Everything else — others' holds, rejected,
    # cancelled, missing — sends the viewer back to the schedule. Mirrors
    # Meetup#visible_to?.
    redirect_to(root_path, alert: "That meetup isn't available.") unless @meetup&.visible_to?(current_user)
  end

  def new
    @meetup = @event.meetups.new
    @selected_slot = params[:slot]
  end

  def create
    @meetup = @event.meetups.new(meetup_params)
    @meetup.user = current_user
    @selected_slot = params.dig(:meetup, :slot)
    assign_slot(@meetup, @selected_slot)
    submitted_tags.each { |tag| @meetup.meetup_tags.build(tag: tag) }

    if @meetup.save
      redirect_to meetup_path(@meetup.public_id), notice: "Your meetup was submitted for review."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @selected_slot = current_slot(@meetup)
  end

  def update
    @selected_slot = params.dig(:meetup, :slot)

    Meetup.transaction do
      @meetup.assign_attributes(meetup_params)
      assign_slot(@meetup, @selected_slot)
      @meetup.tags = submitted_tags
      @meetup.save!
    end

    redirect_to meetup_path(@meetup.public_id), notice: "Your meetup was updated."
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  # Frees the slot and notifies the host and attendees (see Meetup#cancel!).
  def cancel
    @meetup.cancel!
    redirect_to root_path, notice: "“#{@meetup.title}” was cancelled."
  end

  private

  def require_current_event
    @event = Event.current
    redirect_to root_path, alert: "There's no event accepting meetups right now." if @event.nil?
  end

  # Without a scheduling day and an active location there's nothing to book, so
  # the form is unreachable — the "Create a meetup" button is hidden in this
  # state, and hitting the URL directly 404s.
  def require_accepting_meetups
    raise ActionController::RoutingError, "Not Found" unless @event.accepting_meetups?
  end

  def set_editable_meetup
    @meetup = Meetup.find_by(public_id: params[:id])

    unless @meetup&.editable_by?(current_user)
      redirect_to root_path, alert: "You can't edit that meetup."
      return
    end

    @event = @meetup.event
  end

  # Cancellation follows the same permission as editing: the submitter or an
  # admin, while the meetup is still live (pending or approved).
  def set_cancellable_meetup
    @meetup = Meetup.find_by(public_id: params[:id])

    redirect_to root_path, alert: "You can't cancel that meetup." unless @meetup&.editable_by?(current_user)
  end

  def meetup_params
    params.require(:meetup).permit(:title, :description, :location_id)
  end

  # The day/time picker submits one value, "<scheduling_day_id>:<starts_at epoch>",
  # so a single dropdown can carry both the day and the exact hour.
  def assign_slot(meetup, slot)
    day_id, epoch = slot.to_s.split(":")
    meetup.scheduling_day = @event.scheduling_days.find_by(id: day_id)
    meetup.starts_at = epoch.present? ? Time.zone.at(epoch.to_i) : nil
  end

  def current_slot(meetup)
    "#{meetup.scheduling_day_id}:#{meetup.starts_at.to_i}" if meetup.starts_at
  end

  # The event's tags matching the submitted ids (ignores blanks / foreign ids).
  def submitted_tags
    @event.tags.where(id: Array(params.dig(:meetup, :tag_ids)).reject(&:blank?))
  end
end
