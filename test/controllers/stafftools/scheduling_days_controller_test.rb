# frozen_string_literal: true

require "test_helper"

module Stafftools
  class SchedulingDaysControllerTest < ActionDispatch::IntegrationTest
    setup { sign_in users(:admin) }

    test "index lists the event's days" do
      get stafftools_scheduling_days_path
      assert_response :success
      assert_match "September 12, 2026", response.body
    end

    test "creates a day" do
      assert_difference -> { SchedulingDay.count }, 1 do
        post stafftools_scheduling_days_path, params: {
          scheduling_day: { date: "2026-09-13", start_time: "11:00", end_time: "16:00" }
        }
      end
      assert_redirected_to stafftools_scheduling_days_path
      assert_equal events(:expo).id, SchedulingDay.order(:created_at).last.event_id
    end

    test "rejects an invalid day" do
      assert_no_difference -> { SchedulingDay.count } do
        post stafftools_scheduling_days_path, params: {
          scheduling_day: { date: "2026-09-13", start_time: "16:00", end_time: "11:00" }
        }
      end
      assert_response :unprocessable_entity
    end

    test "updates a day" do
      patch stafftools_scheduling_day_path(scheduling_days(:friday)), params: {
        scheduling_day: { date: "2026-09-12", start_time: "09:00", end_time: "17:00" }
      }
      assert_redirected_to stafftools_scheduling_days_path
      assert_equal 9, scheduling_days(:friday).reload.start_time.hour
    end

    test "destroying a day with meetups is blocked" do
      assert_no_difference -> { SchedulingDay.count } do
        delete stafftools_scheduling_day_path(scheduling_days(:friday))
      end
      assert_redirected_to stafftools_scheduling_days_path
      follow_redirect!
      assert_match "still has meetups", response.body
    end
  end
end
