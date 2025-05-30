# frozen_string_literal: true

class MapsController < ApplicationController

  def show
    render "maps/show", locals: { meetup_areas: MeetupArea.all }
  end
end
