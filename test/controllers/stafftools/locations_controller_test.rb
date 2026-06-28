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
  end
end
