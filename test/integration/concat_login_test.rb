# frozen_string_literal: true

require "test_helper"

class ConcatLoginTest < ActionDispatch::IntegrationTest
  # A modern UA so `allow_browser versions: :modern` doesn't reject the request.
  UA = { "HTTP_USER_AGENT" => "Mozilla/5.0 (Macintosh) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36" }.freeze

  setup do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:concat] = OmniAuth::AuthHash.new(
      provider: "concat",
      uid: "990001",
      info: { username: "test_attendee", email: "attendee@example.com", image: "https://cdn.example.com/pic.png" }
    )
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:concat] = nil
  end

  test "concat callback signs the user in, persists, and logs out" do
    assert_difference -> { User.count } => 1, -> { UserSession.count } => 1 do
      get "/auth/concat/callback", headers: UA
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_match "Signed in as test_attendee", response.body
    assert_match "Log out", response.body

    user = User.find_by!(uid: 990001)
    assert_equal "test_attendee", user.login
    assert_equal "attendee@example.com", user.email
    assert_equal "https://cdn.example.com/pic.png", user.profile_picture_url

    # Session persists across requests via the cookie.
    get "/", headers: UA
    assert_match "Log out", response.body

    # Logging out revokes the session and clears the UI.
    delete logout_path, headers: UA
    assert_redirected_to root_path
    follow_redirect!
    assert_match "Log in", response.body
    assert_no_match "Log out", response.body
    assert_predicate user.user_sessions.sole, :revoked?
  end

  test "login succeeds when a stale local row holds the incoming username and email" do
    stale = User.create!(uid: 880001, login: "test_attendee", email: "attendee@example.com")

    assert_difference -> { User.count } => 1 do
      get "/auth/concat/callback", headers: UA
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_match "Signed in as test_attendee", response.body

    new_user = User.find_by!(uid: 990001)
    assert_equal "test_attendee", new_user.login
    assert_equal "attendee@example.com", new_user.email
    assert_equal "user-880001", stale.reload.login
    assert_equal "user-880001@stale.invalid", stale.email
  end

  test "callback degrades to a redirect if saving the user still fails" do
    original = User.method(:from_omniauth)
    User.define_singleton_method(:from_omniauth) { |*| raise ActiveRecord::RecordNotUnique }
    begin
      get "/auth/concat/callback", headers: UA
    ensure
      User.define_singleton_method(:from_omniauth, original)
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_match "Sign in failed", response.body
  end

  test "suspended user is denied" do
    User.create!(uid: 990001, login: "test_attendee", email: "attendee@example.com", suspended_at: Time.current)

    assert_no_difference -> { UserSession.count } do
      get "/auth/concat/callback", headers: UA
    end
    follow_redirect!
    assert_match "suspended", response.body
    assert_match "Log in", response.body
  end
end
