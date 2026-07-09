# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  def auth_hash(uid:, username:, email:, image: nil)
    OmniAuth::AuthHash.new(
      provider: "concat",
      uid: uid.to_s,
      info: { username: username, email: email, image: image }
    )
  end

  test "from_omniauth creates a new user" do
    user = User.from_omniauth(auth_hash(uid: 990001, username: "newbie", email: "newbie@example.com"))

    assert_equal "newbie", user.login
    assert_equal "newbie@example.com", user.email
  end

  test "from_omniauth parks a stale row holding the incoming login" do
    stale = users(:member)
    user = User.from_omniauth(auth_hash(uid: 990001, username: "member", email: "newbie@example.com"))

    assert_equal "member", user.login
    assert_equal "user-1002", stale.reload.login
    assert_equal "member@example.com", stale.email
  end

  test "from_omniauth parks a stale row holding the incoming email" do
    stale = users(:member)
    user = User.from_omniauth(auth_hash(uid: 990001, username: "newbie", email: "member@example.com"))

    assert_equal "member@example.com", user.email
    assert_equal "user-1002@stale.invalid", stale.reload.email
    assert_equal "member", stale.login
  end

  test "from_omniauth parks login and email collisions across two different stale rows" do
    stale_login = users(:member)
    stale_email = users(:guest)
    user = User.from_omniauth(auth_hash(uid: 990001, username: "member", email: "guest@example.com"))

    assert_equal "member", user.login
    assert_equal "guest@example.com", user.email
    assert_equal "user-1002", stale_login.reload.login
    assert_equal "user-1003@stale.invalid", stale_email.reload.email
  end

  test "from_omniauth parks both values of a single stale row" do
    stale = users(:member)
    user = User.from_omniauth(auth_hash(uid: 990001, username: "member", email: "member@example.com"))

    assert_equal "member", user.login
    assert_equal "member@example.com", user.email
    assert_equal "user-1002", stale.reload.login
    assert_equal "user-1002@stale.invalid", stale.email
  end

  test "parked user re-syncs their real values on their next login" do
    stale = users(:member)
    User.from_omniauth(auth_hash(uid: 990001, username: "member", email: "member@example.com"))

    User.from_omniauth(auth_hash(uid: stale.uid, username: "renamed_member", email: "renamed@example.com"))

    assert_equal "renamed_member", stale.reload.login
    assert_equal "renamed@example.com", stale.email
  end

  test "placeholder login collision falls back to a suffixed placeholder" do
    User.create!(uid: 555, login: "user-1002", email: "squatter@example.com")
    stale = users(:member)
    User.from_omniauth(auth_hash(uid: 990001, username: "member", email: "newbie@example.com"))

    assert_match(/\Auser-1002-\h{8}\z/, stale.reload.login)
  end

  test "returning user with unchanged values does not disturb other rows" do
    user = users(:member)

    assert_no_changes -> { users(:guest).reload.attributes } do
      User.from_omniauth(auth_hash(uid: user.uid, username: "member", email: "member@example.com"))
    end
  end
end
