# frozen_string_literal: true

require "test_helper"

module Stafftools
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:admin)
    end

    test "lists meetups with RSVPs ranked by attendee count" do
      Attendance.create!(user: users(:member), meetup: meetups(:pending_vtuber))
      Attendance.create!(user: users(:admin), meetup: meetups(:pending_vtuber))

      get stafftools_root_path
      assert_response :success

      assert_match "Most RSVP'd meetups", response.body
      # pending_vtuber (2 RSVPs) should rank above approved_cosplay (1 RSVP).
      assert_operator response.body.index(meetups(:pending_vtuber).title), :<,
        response.body.index(meetups(:approved_cosplay).title)
    end

    test "shows an empty state when nothing has RSVPs" do
      Attendance.delete_all

      get stafftools_root_path
      assert_response :success
      assert_match "No RSVPs yet", response.body
    end
  end
end
