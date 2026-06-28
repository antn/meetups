ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  # A modern UA so `allow_browser versions: :modern` doesn't reject requests.
  MODERN_UA = { "HTTP_USER_AGENT" => "Mozilla/5.0 (Macintosh) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36" }.freeze

  # Establish a signed-in session for `user` by minting a real UserSession and
  # planting its raw key in the session cookie (mirrors Authentication#login_user).
  def sign_in(user)
    key = UserSession.generate_session_key
    user.user_sessions.create!(token: key.token, accessed_at: Time.current)
    cookies[Authentication::COOKIE_NAME] = key.key
  end

  # Default a modern UA onto every request so the browser guard lets them through.
  def process(method, path, **kwargs)
    kwargs[:headers] = MODERN_UA.merge(kwargs[:headers] || {})
    super
  end
end
