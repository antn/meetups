# frozen_string_literal: true

# A single meetup within an hour slot. Renders differently per what the viewer is
# allowed to see (Meetup#visible_to?):
#   - approved            -> full details, brand accent
#   - pending + visible   -> full details (submitter or admin), amber accent
#   - pending + hidden    -> a bare "hold" on the slot, details hidden
class MeetupCardComponent < ApplicationComponent
  def initialize(meetup:, viewer: nil)
    @meetup = meetup
    @viewer = viewer
  end

  private

  attr_reader :meetup, :viewer

  def status
    meetup.status.to_sym
  end

  # Whether the viewer may see this meetup's details, vs. just a hold on the slot.
  def visible?
    return @visible if defined?(@visible)

    @visible = meetup.visible_to?(viewer)
  end

  # A pending meetup belonging to someone else: only the hold is shown.
  def hold?
    !visible?
  end

  # Visible meetups open a detail page; holds have no viewable details.
  def clickable?
    visible?
  end

  # The viewer is hosting this meetup.
  def own?
    viewer.present? && viewer.id == meetup.user_id
  end

  def container_classes
    if status == :approved
      "bg-white ring-1 ring-gray-200 transition hover:shadow-md hover:ring-brand-purple/40"
    elsif hold?
      "border border-dashed border-gray-300 bg-gray-50"
    else # pending and visible to this viewer (submitter or admin)
      "bg-amber-50 ring-1 ring-amber-200"
    end
  end

  # Pending meetups the viewer can see are labelled; approved ones read as
  # confirmed from the clean card, and others' holds need no badge.
  def badge_label
    "Pending review" if status == :pending && visible?
  end

  def badge_classes
    "bg-amber-100 text-amber-700"
  end
end
