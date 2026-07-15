# frozen_string_literal: true

require "test_helper"

class MeetupsHelperTest < ActionView::TestCase
  test "booked slot keys include blocked hours" do
    day = scheduling_days(:friday)
    location = locations(:main_stage)
    blocked = LocationBlockedHour.create!(location: location, scheduling_day: day, hour: 12)

    keys = meetup_booked_slot_keys(events(:expo))
    assert_includes keys, "#{location.id}:#{blocked.starts_at.to_i}"
  end

  test "booked slot keys drop the edited meetup's own slot even when its hour is blocked" do
    meetup = meetups(:approved_cosplay) # 11 AM PDT
    LocationBlockedHour.create!(location: meetup.location, scheduling_day: meetup.scheduling_day, hour: 11)

    keys = meetup_booked_slot_keys(events(:expo), except: meetup)
    assert_not_includes keys, "#{meetup.location_id}:#{meetup.starts_at.to_i}"
  end
end
