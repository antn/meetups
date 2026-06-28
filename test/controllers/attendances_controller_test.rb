# frozen_string_literal: true

require "test_helper"

class AttendancesControllerTest < ActionDispatch::IntegrationTest
  test "rsvp requires sign in" do
    assert_no_difference -> { Attendance.count } do
      post meetup_attendance_path(meetups(:approved_cosplay).public_id)
    end
    assert_redirected_to root_path
  end

  test "creates an attendance and returns the updated button" do
    sign_in users(:guest) # guest hosts nothing, so the toggle applies
    assert_difference -> { Attendance.count }, 1 do
      post meetup_attendance_path(meetups(:approved_cosplay).public_id), as: :turbo_stream
    end
    assert_response :success
    assert Attendance.exists?(user: users(:guest), meetup: meetups(:approved_cosplay))
    assert_match "Going", response.body
  end

  test "rsvp is idempotent" do
    sign_in users(:guest)
    2.times { post meetup_attendance_path(meetups(:approved_cosplay).public_id), as: :turbo_stream }
    assert_equal 1, Attendance.where(user: users(:guest), meetup: meetups(:approved_cosplay)).count
  end

  test "destroy removes the attendance" do
    sign_in users(:admin) # admin attends approved_cosplay via fixture
    assert_difference -> { Attendance.count }, -1 do
      delete meetup_attendance_path(meetups(:approved_cosplay).public_id), as: :turbo_stream
    end
    assert_not Attendance.exists?(user: users(:admin), meetup: meetups(:approved_cosplay))
    assert_match "I'm going!", response.body
  end

  test "can't rsvp to a meetup that isn't approved" do
    sign_in users(:guest)
    assert_no_difference -> { Attendance.count } do
      post meetup_attendance_path(meetups(:pending_vtuber).public_id)
    end
    assert_redirected_to root_path
  end
end
