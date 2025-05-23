# frozen_string_literal: true

class Stafftools::MeetupsController < StafftoolsController
  before_action :ensure_this_meetup, only: [:show, :update]

  def index
    meetups = Meetup.where(state: filter).includes(:meetup_area).order(starts_at: :asc)
    render "stafftools/meetups/index", locals: { meetups: meetups }
  end

  def show
    render "stafftools/meetups/show", locals: { meetup: this_meetup }
  end

  def update
    if this_meetup.update(meetup_params)
      flash[:notice] = "Updated state to #{this_meetup.state}"
      redirect_to stafftools_meetup_path(this_meetup)
    else
      flash[:error] = this_meetup.errors.full_messages.to_sentence
      render "stafftools/meetups/show", locals: { meetup: this_meetup }, status: :unprocessable_entity
    end
  end

  def destroy
    if this_meetup.update(state: :cancelled)
      flash[:notice] = "Cancelled #{this_meetup.name}!"
    else
      flash[:error] = "Couldn't cancel meetup: #{this_meetup.errors.full_messages}"
    end

    redirect_to stafftools_meetup_path(this_meetup)
  end

  private

  def filter
    if params[:filter] == "approved"
      :approved
    elsif params[:filter] == "rejected"
      :rejected
    elsif params[:filter] == "cancelled"
      :cancelled
    else
      :pending
    end
  end

  def this_meetup
    @this_meetup ||= Meetup.find_by(id: params[:id])
  end

  def ensure_this_meetup
    render_404 unless this_meetup.present?
  end

  def meetup_params
    params.require(:meetup).permit(:state)
  end
end
