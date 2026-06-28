# frozen_string_literal: true

require "test_helper"

module Stafftools
  class AccessControlTest < ActionDispatch::IntegrationTest
    test "anonymous visitors get a 404" do
      get stafftools_root_path
      assert_response :not_found
    end

    test "non-admins get a 404" do
      sign_in users(:member)
      get stafftools_scheduling_days_path
      assert_response :not_found
    end

    test "admins can reach the dashboard" do
      sign_in users(:admin)
      get stafftools_root_path
      assert_response :success
      assert_match "Dashboard", response.body
    end
  end
end
