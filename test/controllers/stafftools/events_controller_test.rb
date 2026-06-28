# frozen_string_literal: true

require "test_helper"

module Stafftools
  class EventsControllerTest < ActionDispatch::IntegrationTest
    setup { sign_in users(:admin) }

    test "index lists events" do
      get stafftools_events_path
      assert_response :success
      assert_match "OffKai Expo", response.body
    end

    test "creates an inactive event" do
      assert_difference -> { Event.count }, 1 do
        post stafftools_events_path, params: {
          event: { name: "Winter Con", time_zone: "Eastern Time (US & Canada)" }
        }
      end
      assert_redirected_to stafftools_events_path
      created = Event.find_by!(name: "Winter Con")
      assert_not created.active?
    end

    test "rejects an event with an unknown time zone" do
      assert_no_difference -> { Event.count } do
        post stafftools_events_path, params: {
          event: { name: "Bad Con", time_zone: "Mars/Olympus" }
        }
      end
      assert_response :unprocessable_entity
    end

    test "updates an event" do
      patch stafftools_event_path(events(:expo)), params: {
        event: { name: "OffKai Expo 2026", time_zone: "America/Los_Angeles" }
      }
      assert_redirected_to stafftools_events_path
      assert_equal "OffKai Expo 2026", events(:expo).reload.name
    end

    test "activate makes the event the sole active one" do
      newcomer = Event.create!(name: "Winter Con", time_zone: "Eastern Time (US & Canada)")
      patch activate_stafftools_event_path(newcomer)
      assert_redirected_to stafftools_events_path
      assert newcomer.reload.active?
      assert_not events(:expo).reload.active?
    end

    test "deleting an event with associations is blocked" do
      assert_no_difference -> { Event.count } do
        delete stafftools_event_path(events(:expo))
      end
      assert_redirected_to stafftools_events_path
      follow_redirect!
      assert_match "delete an event that still has", response.body
    end

    test "deletes an event with no associations" do
      newcomer = Event.create!(name: "Winter Con", time_zone: "Eastern Time (US & Canada)")
      assert_difference -> { Event.count }, -1 do
        delete stafftools_event_path(newcomer)
      end
      assert_redirected_to stafftools_events_path
    end
  end
end
