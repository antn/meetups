# frozen_string_literal: true

class Stafftools::MeetupDaysController < StafftoolsController
  before_action :ensure_this_meetup, only: [:edit, :update, :destroy]

  def index
    render "stafftools/meetup_days/index", locals: {
      meetup_days: meetup_days,
    }
  end

  def new
    render "stafftools/meetup_days/new", locals: { meetup_day: MeetupDay.new }
  end

  def edit
    render "stafftools/meetup_days/edit", locals: { meetup_day: this_meetup }
  end

  def update
    if this_meetup.update(meetup_params)
      flash[:notice] = "Updated meetup day."
      redirect_to stafftools_meetup_days_path
    else
      render "stafftools/meetup_days/edit",
        locals: { meetup_day: this_meetup },
        status: :unprocessable_entity
    end
  end

  def create
    meetup_day = MeetupDay.new(meetup_params)

    if meetup_day.save
      flash[:notice] = "Meetup day updated!"
      redirect_to stafftools_meetup_days_path
    else
      render "stafftools/meetup_days/new",
        locals: { meetup_day: meetup_day },
        status: :unprocessable_entity
    end
  end

  def destroy
    flash[:notice] = "Meetup day deleted."
    meetup_day.destroy
    redirect_to stafftools_meetup_days_path
  end

  private

  def meetup_days
    @meetup_days ||= MeetupDay.all
  end

  def meetup_params
    params.require(:meetup_day).permit(:starts_at, :ends_at).transform_values do |value|
      Time.use_zone("Pacific Time (US & Canada)") { Time.zone.parse(value).utc } if value.present?
    end
  end

  def this_meetup
    @this_meetup = MeetupDay.find_by(id: params[:id])
  end

  def ensure_this_meetup
    render_404 unless this_meetup.present?
  end
end
