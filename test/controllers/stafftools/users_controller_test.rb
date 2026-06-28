# frozen_string_literal: true

require "test_helper"

module Stafftools
  class UsersControllerTest < ActionDispatch::IntegrationTest
    setup { sign_in users(:admin) }

    test "index lists users" do
      get stafftools_users_path
      assert_response :success
      assert_match users(:member).login, response.body
      assert_match users(:guest).login, response.body
    end

    test "search filters by login" do
      get stafftools_users_path(q: "member")
      assert_response :success
      assert_match users(:member).login, response.body
      assert_no_match(/\bguest\b/, response.body)
    end

    test "search matches the external uid exactly" do
      get stafftools_users_path(q: users(:guest).uid.to_s)
      assert_response :success
      assert_match users(:guest).login, response.body
      assert_no_match(/>member</, response.body)
    end

    test "suspends a user and revokes their sessions" do
      member = users(:member)
      session = member.user_sessions.create!(
        token: UserSession.generate_session_key.token,
        accessed_at: Time.current
      )

      patch suspend_stafftools_user_path(member)
      assert_redirected_to stafftools_users_path
      assert member.reload.suspended?
      assert session.reload.revoked?
    end

    test "unsuspends a user" do
      member = users(:member)
      member.suspend!

      patch unsuspend_stafftools_user_path(member)
      assert_redirected_to stafftools_users_path
      assert_not member.reload.suspended?
    end

    test "refuses to suspend a site admin" do
      patch suspend_stafftools_user_path(users(:admin))
      assert_redirected_to stafftools_users_path
      assert_not users(:admin).reload.suspended?
    end

    test "non-admins get a 404" do
      sign_in users(:member)
      get stafftools_users_path
      assert_response :not_found
    end
  end
end
