# frozen_string_literal: true

# "I'm going!" RSVP toggle for an (approved) meetup, with a live attendee count.
# Persisted via AttendancesController; the button toggles between create (POST)
# and destroy (DELETE) and is swapped in place by a Turbo Stream. Attending = green.
class RsvpButtonComponent < ApplicationComponent
  BTN_BASE = "inline-flex cursor-pointer items-center gap-1.5 rounded-full border px-3 py-1 text-xs font-semibold transition"
  BTN_IDLE = "border-gray-300 text-gray-700 hover:border-gray-400 hover:bg-gray-50 hover:text-gray-900"
  BTN_ACTIVE = "border-green-600 bg-green-600 text-white hover:bg-green-700"

  COUNT_BASE = "ml-0.5 rounded-full px-1.5 py-0.5 tabular-nums"
  COUNT_IDLE = "bg-gray-100 text-gray-600"
  COUNT_ACTIVE = "bg-white text-green-700"

  def initialize(meetup:, viewer: nil)
    @meetup = meetup
    @viewer = viewer
  end

  private

  attr_reader :meetup, :viewer

  # Wrapper id is the Turbo Stream replace target (matches dom_id(@meetup, :rsvp)
  # in attendances/*.turbo_stream.erb).
  def dom_id
    ActionView::RecordIdentifier.dom_id(meetup, :rsvp)
  end

  def signed_in?
    viewer.present?
  end

  # The host doesn't RSVP to their own meetup — they just see who's coming.
  def host?
    viewer.present? && viewer.id == meetup.user_id
  end

  def going?
    return false if viewer.nil?

    meetup.attendances.any? { |attendance| attendance.user_id == viewer.id }
  end

  def count
    meetup.attendances.size
  end

  def attendee_summary
    count.zero? ? "No RSVPs yet" : "#{helpers.pluralize(count, "person")} going"
  end

  def button_class
    "#{BTN_BASE} #{going? ? BTN_ACTIVE : BTN_IDLE}"
  end

  def count_class
    "#{COUNT_BASE} #{going? ? COUNT_ACTIVE : COUNT_IDLE}"
  end
end
