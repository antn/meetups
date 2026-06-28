# frozen_string_literal: true

# The dashed "request slot" affordance shown when a timeslot still has open
# locations. For signed-in viewers it links to the meetup form with this
# day/time pre-selected; for signed-out visitors it opens the sign-in modal.
class OpenSlotComponent < ApplicationComponent
  STYLE = "flex w-full cursor-pointer items-center justify-center gap-2 rounded-2xl border border-dashed border-gray-200 py-3 text-sm font-medium text-gray-400 no-underline transition hover:border-brand-purple/50 hover:bg-brand-purple/5 hover:text-brand-purple"

  def initialize(count:, slot_param:, signed_in: false)
    @count = count
    @slot_param = slot_param
    @signed_in = signed_in
  end

  private

  attr_reader :count, :slot_param, :signed_in

  def label
    "#{count} #{count == 1 ? "location" : "locations"} open · Request slot"
  end
end
