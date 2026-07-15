# frozen_string_literal: true

require "test_helper"

module Stafftools
  class LocationsControllerTest < ActionDispatch::IntegrationTest
    setup { sign_in users(:admin) }

    test "index lists locations" do
      get stafftools_locations_path
      assert_response :success
      assert_match "Main Stage", response.body
      assert_match "Storage Closet", response.body
    end

    test "creates a location" do
      assert_difference -> { Location.count }, 1 do
        post stafftools_locations_path, params: {
          location: { name: "Panel Room A", description: "Up front", active: "1" }
        }
      end
      assert_redirected_to stafftools_locations_path
      created = Location.order(:created_at).last
      assert_equal events(:expo).id, created.event_id
      assert created.active?
    end

    test "creates a location with a map image" do
      image = fixture_file_upload("map.png", "image/png")
      assert_difference -> { Location.count }, 1 do
        post stafftools_locations_path, params: {
          location: { name: "Panel Room B", map_image: image }
        }
      end
      assert_redirected_to stafftools_locations_path
      assert Location.order(:created_at).last.map_image.attached?
    end

    test "rejects an unsupported map image type" do
      file = fixture_file_upload("notes.txt", "text/plain")
      assert_no_difference -> { Location.count } do
        post stafftools_locations_path, params: {
          location: { name: "Panel Room C", map_image: file }
        }
      end
      assert_response :unprocessable_entity
    end

    test "rejects a duplicate name" do
      assert_no_difference -> { Location.count } do
        post stafftools_locations_path, params: { location: { name: "Main Stage" } }
      end
      assert_response :unprocessable_entity
    end

    test "updates a location" do
      patch stafftools_location_path(locations(:storage)), params: {
        location: { name: "Storage Closet", active: "1" }
      }
      assert_redirected_to stafftools_locations_path
      assert locations(:storage).reload.active?
    end

    test "destroying a location with meetups is blocked" do
      assert_no_difference -> { Location.count } do
        delete stafftools_location_path(locations(:main_stage))
      end
      assert_redirected_to stafftools_locations_path
      follow_redirect!
      assert_match "still has meetups", response.body
    end

    test "destroys an unused location" do
      assert_difference -> { Location.count }, -1 do
        delete stafftools_location_path(locations(:storage))
      end
      assert_redirected_to stafftools_locations_path
    end

    test "edit form renders the availability grid" do
      get edit_stafftools_location_path(locations(:main_stage))
      assert_response :success
      assert_match "Hourly availability", response.body
    end

    test "update syncs blocked hours from the availability grid" do
      location = locations(:main_stage)
      day = scheduling_days(:friday)
      all_keys = day.valid_start_times.map { |t| "#{day.id}:#{t.hour}" }

      patch stafftools_location_path(location), params: {
        location: { name: "Main Stage", active: "1", available_hour_keys: [ "" ] + all_keys - [ "#{day.id}:12", "#{day.id}:13" ] }
      }
      assert_redirected_to stafftools_locations_path
      assert_equal [ 12, 13 ], location.blocked_hours.order(:hour).pluck(:hour)

      # Re-submitting with every hour available clears the blocks.
      patch stafftools_location_path(location), params: {
        location: { name: "Main Stage", active: "1", available_hour_keys: [ "" ] + all_keys }
      }
      assert_empty location.blocked_hours.reload
    end

    test "update without the availability grid leaves blocked hours alone" do
      location = locations(:main_stage)
      LocationBlockedHour.create!(location: location, scheduling_day: scheduling_days(:friday), hour: 12)

      patch stafftools_location_path(location), params: { location: { name: "Main Stage" } }
      assert_equal [ 12 ], location.blocked_hours.pluck(:hour)
    end
  end
end
