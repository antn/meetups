# frozen_string_literal: true

class Stafftools::MeetupAreasController < StafftoolsController
  before_action :ensure_this_meetup, only: [:edit, :destroy]

  def index
    render "stafftools/meetup_areas/index", locals: {
      meetup_areas: meetup_areas,
    }
  end

  def new
    render "stafftools/meetup_areas/new", locals: { meetup_area: MeetupArea.new }
  end

  def edit
    render "stafftools/meetup_areas/edit", locals: { meetup_area: this_meetup }
  end

  def update
    if this_meetup.update(meetup_params)
      flash[:notice] = "Meetup area updated!"
      redirect_to stafftools_meetup_areas_path
    else
      render "stafftools/meetup_areas/edit",
        locals: { meetup_area: this_meetup },
        status: :unprocessable_entity
    end
  end

  def create
    meetup_area = MeetupArea.new(meetup_params)

    if meetup_area.save
      flash[:notice] = "Meetup area created!"
      redirect_to stafftools_meetup_areas_path
    else
      render "stafftools/meetup_areas/new",
        locals: { meetup_area: meetup_area },
        status: :unprocessable_entity
    end
  end

  def destroy
    this_meetup.destroy
    flash[:notice] = "Meetup area deleted."
    redirect_to stafftools_meetup_areas_path
  end

  private

  def meetup_areas
    @meetup_areas ||= MeetupArea.all
  end

  def meetup_params
    params.require(:meetup_area).permit(:name, :location, :description)
  end

  def this_meetup
    @this_meetup = MeetupArea.find_by(id: params[:id])
  end

  def ensure_this_meetup
    render_404 unless this_meetup.present?
  end
end
