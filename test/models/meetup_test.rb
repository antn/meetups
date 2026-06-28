# frozen_string_literal: true

require "test_helper"

class MeetupTest < ActiveSupport::TestCase
  def build_meetup(description:)
    day = scheduling_days(:friday)
    Meetup.new(
      event: events(:expo),
      user: users(:member),
      location: locations(:main_stage),
      scheduling_day: day,
      starts_at: day.valid_start_times.find { |t| t.hour == 13 },
      title: "Sample",
      description: description,
      tags: [ tags(:gaming) ]
    )
  end

  test "description is required" do
    meetup = build_meetup(description: "")
    assert_not meetup.valid?
    assert_includes meetup.errors[:description], "can't be blank"
  end

  test "description must be at least 15 characters" do
    assert_not build_meetup(description: "a" * 14).valid?
    assert build_meetup(description: "a" * 15).valid?
  end

  test "description must be at most 280 characters" do
    assert_not build_meetup(description: "a" * 281).valid?
    assert build_meetup(description: "a" * 280).valid?
  end

  test "tagged_with returns meetups carrying any of the given tags" do
    cosplay = Meetup.tagged_with([ tags(:cosplay).public_id ])
    assert_includes cosplay, meetups(:approved_cosplay)

    gaming = Meetup.tagged_with([ tags(:gaming).public_id ])
    assert_not_includes gaming, meetups(:approved_cosplay)
  end

  test "can't claim a timeslot that has already passed" do
    past_day = events(:expo).scheduling_days.create!(date: Date.current - 1, start_time: "10:00", end_time: "17:00")
    meetup = Meetup.new(
      event: events(:expo), user: users(:member), location: locations(:main_stage),
      scheduling_day: past_day, starts_at: past_day.valid_start_times.first,
      title: "Old news", description: "A meetup whose time has passed.", tags: [ tags(:gaming) ]
    )
    assert_not meetup.valid?
    assert_includes meetup.errors[:starts_at], "has already passed"
  end

  test "editable_by? allows the owner and admins while live" do
    meetup = meetups(:pending_vtuber) # owned by member, pending
    assert meetup.editable_by?(users(:member))
    assert meetup.editable_by?(users(:admin))
    assert_not meetup.editable_by?(nil)

    stranger = User.create!(uid: 9100, login: "nope", email: "n@example.com")
    assert_not meetup.editable_by?(stranger)
  end

  test "editable_by? is false once rejected or cancelled" do
    meetup = meetups(:pending_vtuber)
    meetup.reject!(by: users(:admin), reason: "no")
    assert_not meetup.editable_by?(users(:member))
    assert_not meetup.editable_by?(users(:admin))
  end
end
