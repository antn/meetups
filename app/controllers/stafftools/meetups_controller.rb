# frozen_string_literal: true

module Stafftools
  class MeetupsController < ApplicationController
    before_action :require_current_event
    before_action :set_meetup, only: %i[show approve reject edit update]
    before_action :require_editable, only: %i[edit update]

    STATUSES = Meetup.statuses.keys.freeze

    def index
      @status = STATUSES.include?(params[:status]) ? params[:status] : "pending"
      @status_counts = status_counts

      @meetups = current_event.meetups.where(status: @status)
        .includes(:user, :location, :scheduling_day, :tags)
        .order(:starts_at)
    end

    def show; end

    def edit
      @selected_slot = current_slot(@meetup)
    end

    def update
      @selected_slot = params.dig(:meetup, :slot)

      Meetup.transaction do
        @meetup.assign_attributes(meetup_params)
        assign_slot(@meetup, @selected_slot)
        @meetup.tags = current_event.tags.where(id: tag_ids_param)
        @meetup.save!
      end

      redirect_to stafftools_meetup_path(@meetup), notice: "Meetup updated."
    rescue ActiveRecord::RecordInvalid
      render :edit, status: :unprocessable_entity
    end

    def approve
      @meetup.approve!(by: current_user)
      notice = "Approved “#{@meetup.title}.”"
      respond_to do |format|
        format.html { redirect_to stafftools_meetups_path, notice: notice }
        format.json { render json: { ok: true, notice: notice, counts: status_counts } }
      end
    rescue ActiveRecord::RecordInvalid => e
      alert = "Couldn't approve: #{e.record.errors.full_messages.to_sentence}"
      respond_to do |format|
        format.html { redirect_to stafftools_meetups_path, alert: alert }
        format.json { render json: { ok: false, alert: alert }, status: :unprocessable_entity }
      end
    end

    def reject
      reason = params[:rejection_reason].to_s.strip

      if reason.blank?
        alert = "A reason is required to reject a meetup."
        respond_to do |format|
          format.html { redirect_to stafftools_meetups_path, alert: alert }
          format.json { render json: { ok: false, alert: alert }, status: :unprocessable_entity }
        end
        return
      end

      @meetup.reject!(by: current_user, reason: reason)
      notice = "Rejected “#{@meetup.title}.”"
      respond_to do |format|
        format.html { redirect_to stafftools_meetups_path, notice: notice }
        format.json { render json: { ok: true, notice: notice, counts: status_counts } }
      end
    end

    private

    def status_counts
      STATUSES.index_with { |status| current_event.meetups.where(status: status).count }
    end

    def set_meetup
      @meetup = current_event.meetups.find(params[:id])
    end

    def require_editable
      redirect_to stafftools_meetups_path, alert: "That meetup can't be edited." unless @meetup.editable_by?(current_user)
    end

    def meetup_params
      params.require(:meetup).permit(:title, :description, :location_id)
    end

    # Slot value is "<scheduling_day_id>:<starts_at epoch>" (see the meetup form).
    def assign_slot(meetup, slot)
      day_id, epoch = slot.to_s.split(":")
      meetup.scheduling_day = current_event.scheduling_days.find_by(id: day_id)
      meetup.starts_at = epoch.present? ? Time.zone.at(epoch.to_i) : nil
    end

    def tag_ids_param
      Array(params.dig(:meetup, :tag_ids)).reject(&:blank?)
    end

    def current_slot(meetup)
      "#{meetup.scheduling_day_id}:#{meetup.starts_at.to_i}" if meetup.starts_at
    end
  end
end
