# frozen_string_literal: true

require "test_helper"

class AttendanceTest < ActiveSupport::TestCase
  test "a user can attend a meetup" do
    attendance = Attendance.new(user: users(:member), meetup: meetups(:approved_cosplay))
    assert attendance.valid?
  end

  test "a user can't attend the same meetup twice" do
    Attendance.create!(user: users(:member), meetup: meetups(:approved_cosplay))
    dup = Attendance.new(user: users(:member), meetup: meetups(:approved_cosplay))
    assert_not dup.valid?
    assert_includes dup.errors[:meetup_id], "has already been taken"
  end

  test "gets a public_id on create" do
    attendance = Attendance.create!(user: users(:member), meetup: meetups(:approved_cosplay))
    assert attendance.public_id.present?
  end

  test "meetup exposes its attendees" do
    assert_includes meetups(:approved_cosplay).attendees, users(:admin)
  end

  test "user exposes the meetups they're attending" do
    assert_includes users(:admin).attending_meetups, meetups(:approved_cosplay)
  end
end
