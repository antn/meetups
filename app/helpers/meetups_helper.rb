# frozen_string_literal: true

module MeetupsHelper
  # Badge classes per meetup status. Spelled out literally for Tailwind's scanner.
  MEETUP_STATUS_BADGE = {
    "pending" => "bg-amber-50 text-amber-700 ring-amber-200",
    "approved" => "bg-green-50 text-green-700 ring-green-200",
    "rejected" => "bg-red-50 text-red-700 ring-red-200",
    "cancelled" => "bg-gray-100 text-gray-500 ring-gray-200"
  }.freeze

  def meetup_status_badge_classes(status)
    MEETUP_STATUS_BADGE.fetch(status.to_s, MEETUP_STATUS_BADGE["pending"])
  end

  # Day/time options for the meetup form, grouped into one <optgroup> per
  # scheduling day so the dropdown reads cleanly. Each option's value packs the
  # day id and the absolute start time (epoch) so a single dropdown carries both.
  def meetup_slot_groups(event)
    event.scheduling_days.order(:date).map do |day|
      {
        label: day.date.strftime("%A, %b %-d"),
        options: day.valid_start_times.map do |start_time|
          {
            value: "#{day.id}:#{start_time.to_i}",
            epoch: start_time.to_i,
            # Short label for the grouped list; full label for the collapsed
            # control so the selected day+time is unambiguous (swapped in JS).
            label: start_time.strftime("%-l:%M %p"),
            full: "#{day.date.strftime("%a %b %-d")} · #{start_time.strftime("%-l:%M %p")}"
          }
        end
      }
    end
  end

  # "<location_id>:<epoch>" keys for every taken slot, handed to the form's
  # Catalyst element so it can gray out conflicting locations/times. When editing,
  # `except` drops the meetup's own slot so it isn't grayed against itself.
  def meetup_booked_slot_keys(event, except: nil)
    scope = event.meetups.visible
    scope = scope.where.not(id: except.id) if except&.persisted?
    scope.pluck(:location_id, :starts_at).map do |location_id, starts_at|
      "#{location_id}:#{starts_at.to_i}"
    end
  end
end
