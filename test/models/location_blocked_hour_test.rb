# frozen_string_literal: true

require "test_helper"

class LocationBlockedHourTest < ActiveSupport::TestCase
  def build_blocked_hour(hour: 13)
    LocationBlockedHour.new(
      location: locations(:main_stage),
      scheduling_day: scheduling_days(:friday),
      hour: hour
    )
  end

  test "valid for an hour within the day's window" do
    assert build_blocked_hour(hour: 10).valid?
    assert build_blocked_hour(hour: 16).valid?
  end

  test "rejects hours outside the day's window" do
    [ 9, 17, 20 ].each do |hour|
      blocked = build_blocked_hour(hour: hour)
      assert_not blocked.valid?
      assert_includes blocked.errors[:hour], "must be within the scheduling day's hours"
    end
  end

  test "rejects a duplicate hour for the same location and day" do
    build_blocked_hour.save!
    dupe = build_blocked_hour
    assert_not dupe.valid?
    assert_includes dupe.errors[:hour], "has already been taken"
  end

  test "rejects a location and day from different events" do
    other_event = Event.create!(name: "Other Con", time_zone: "America/New_York")
    other_location = other_event.locations.create!(name: "Hall Z")
    blocked = LocationBlockedHour.new(location: other_location, scheduling_day: scheduling_days(:friday), hour: 13)
    assert_not blocked.valid?
    assert_includes blocked.errors[:base], "location and scheduling day must belong to the same event"
  end

  test "starts_at is the blocked hour as an instant in the event's timezone" do
    blocked = build_blocked_hour(hour: 13)
    assert_equal events(:expo).tz.local(2026, 9, 12, 13), blocked.starts_at
  end

  test "location.blocked_at? matches the day and instant" do
    build_blocked_hour(hour: 13).save!
    day = scheduling_days(:friday)
    location = locations(:main_stage)

    blocked_time = day.valid_start_times.find { |t| t.hour == 13 }
    open_time = day.valid_start_times.find { |t| t.hour == 14 }
    assert location.blocked_at?(day, blocked_time)
    assert_not location.blocked_at?(day, open_time)
  end
end
