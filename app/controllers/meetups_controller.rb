# frozen_string_literal: true

class MeetupsController < ApplicationController
  before_action :require_logged_in, except: [:index]
  before_action :requires_adminable_by, only: [:edit, :update, :destroy]

  def index
    render "meetups/index", locals: {
      meetup_days: MeetupDay.order(:starts_at).all,
      meetup_day: meetup_day,
    }
  end

  def new
    days = MeetupDay.order(:starts_at)
    areas = MeetupArea.order(:name)
    slots_by_day_area = {}

    days.each do |day|
      areas.each do |area|
        slots = []
        start_time = day.starts_at
        end_time = day.ends_at
        while start_time < end_time
          slot_taken = Meetup.where(
            meetup_area_id: area.id,
            starts_at: start_time,
            ends_at: start_time + 1.hour
          ).where.not(state: [:cancelled, :rejected]).exists?
          slots << start_time unless slot_taken
          start_time += 1.hour
        end
        slots_by_day_area[[day.id, area.id]] = slots
      end
    end

    render "meetups/new", locals: {
      meetup: Meetup.new,
      days: days,
      areas: areas,
      slots_by_day_area: slots_by_day_area
    }
  end

  def create
    slot_combo = params[:meetup].delete(:slot_combo)
    if slot_combo.present?
      day_id, area_id, starts_at = slot_combo.split("|")
      params[:meetup][:meetup_day_id] = day_id
      params[:meetup][:meetup_area_id] = area_id
      params[:meetup][:starts_at] = starts_at
    end

    meetup = Meetup.new(meetup_params)
    meetup.user = current_user

    # Set ends_at to be 1 hour after starts_at
    if meetup.starts_at.present?
      meetup.ends_at = meetup.starts_at + 1.hour
    end

    if meetup.save
      redirect_to meetups_path, notice: "Meetup requested! You'll receive an email once your request is reviewed."
    else
      # You may want to re-calculate days, areas, slots_by_day_area here for re-render
      days = MeetupDay.order(:starts_at)
      areas = MeetupArea.order(:name)
      slots_by_day_area = {}
      days.each do |day|
        areas.each do |area|
          slots = []
          start_time = day.starts_at
          end_time = day.ends_at
          while start_time < end_time
            slot_taken = Meetup.where(
              meetup_area_id: area.id,
              starts_at: start_time,
              ends_at: start_time + 1.hour
            ).where.not(state: :rejected).exists?
            slots << start_time unless slot_taken
            start_time += 1.hour
          end
          slots_by_day_area[[day.id, area.id]] = slots
        end
      end
      render "meetups/new", locals: { meetup: meetup, days: days, areas: areas, slots_by_day_area: slots_by_day_area }, status: :unprocessable_entity
    end
  end

  def edit
    days = MeetupDay.order(:starts_at)
    areas = MeetupArea.order(:name)
    slots_by_day_area = {}

    days.each do |day|
      areas.each do |area|
        slots = []
        start_time = day.starts_at
        end_time = day.ends_at
        while start_time < end_time
          slot_taken = Meetup.where(
            meetup_area_id: area.id,
            starts_at: start_time,
            ends_at: start_time + 1.hour
          ).where.not(state: :rejected)
          # Allow the current meetup's slot
          slot_taken = slot_taken.where.not(id: this_meetup.id)
          slot_taken = slot_taken.exists?
          slots << start_time unless slot_taken
          start_time += 1.hour
        end
        slots_by_day_area[[day.id, area.id]] = slots
      end
    end

    render "meetups/edit", locals: {
      meetup: this_meetup,
      days: days,
      areas: areas,
      slots_by_day_area: slots_by_day_area
    }
  end

  def update
    slot_combo = params[:meetup].delete(:slot_combo)
    if slot_combo.present?
      day_id, area_id, starts_at = slot_combo.split("|")
      params[:meetup][:meetup_day_id] = day_id
      params[:meetup][:meetup_area_id] = area_id
      params[:meetup][:starts_at] = starts_at
    end

    # Set ends_at to be 1 hour after starts_at
    if params[:meetup][:starts_at].present?
      params[:meetup][:ends_at] = Time.parse(params[:meetup][:starts_at]) + 1.hour
    end

    if this_meetup.update(meetup_params)
      redirect_to edit_meetup_path(this_meetup), notice: "Meetup updated!"
    else
      days = MeetupDay.order(:starts_at)
      areas = MeetupArea.order(:name)
      slots_by_day_area = {}
      days.each do |day|
        areas.each do |area|
          slots = []
          start_time = day.starts_at
          end_time = day.ends_at
          while start_time < end_time
            slot_taken = Meetup.where(
              meetup_area_id: area.id,
              starts_at: start_time,
              ends_at: start_time + 1.hour
            ).where.not(state: [:cancelled, :rejected])
            # Allow the current meetup's slot
            slot_taken = slot_taken.where.not(id: this_meetup.id)
            slot_taken = slot_taken.exists?
            slots << start_time unless slot_taken
            start_time += 1.hour
          end
          slots_by_day_area[[day.id, area.id]] = slots
        end
      end
      render "meetups/edit", locals: { meetup: this_meetup, days: days, areas: areas, slots_by_day_area: slots_by_day_area }, status: :unprocessable_entity
    end
  end

  def destroy
    if this_meetup.update(state: :cancelled)
      flash[:notice] = "Cancelled #{this_meetup.name}!"
    else
      flash[:error] = "Couldn't cancel meetup: #{this_meetup.errors.full_messages}"
    end

    redirect_to root_url
  end

  private

  def this_meetup
    @this_meetup ||= Meetup.find(params[:id])
  end

  def meetup_day
    return @meetup_day if defined?(@meetup_day)

    day = if params[:date].present?
      # Parse the date in Pacific Time and convert it to UTC
      date = Time.use_zone("Pacific Time (US & Canada)") { Time.zone.parse(params[:date]) }
      start_of_day = date.beginning_of_day.utc
      end_of_day = date.end_of_day.utc

      MeetupDay.includes(:listable_meetups).find_by(starts_at: start_of_day..end_of_day)
    else
      MeetupDay.includes(:listable_meetups).order(:starts_at).first
    end

    @meetup_day = day || MeetupDay.first
  end

  def meetup_params
    params.require(:meetup).permit(:name, :description, :starts_at, :ends_at, :meetup_area_id, :meetup_day_id)
  end

  def requires_adminable_by
    this_meetup.adminable_by?(current_user)
  end
end
