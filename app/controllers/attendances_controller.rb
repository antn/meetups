# frozen_string_literal: true

# RSVPs ("I'm going") for a meetup. One attendance per (user, meetup); the
# button toggles between create and destroy via Turbo Streams.
class AttendancesController < ApplicationController
  before_action :require_authentication
  before_action :set_meetup

  def create
    # You can only RSVP to a published meetup.
    if @meetup.approved?
      @meetup.attendances.find_or_create_by!(user: current_user)
    else
      return redirect_back(fallback_location: root_path, alert: "That meetup isn't open for RSVPs.")
    end

    respond_with_button
  end

  def destroy
    @meetup.attendances.where(user: current_user).destroy_all
    respond_with_button
  end

  private

  def set_meetup
    @meetup = Meetup.find_by(public_id: params[:meetup_id])
    redirect_back(fallback_location: root_path, alert: "That meetup isn't available.") if @meetup.nil?
  end

  def respond_with_button
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: meetup_path(@meetup.public_id)) }
    end
  end
end
