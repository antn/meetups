# frozen_string_literal: true

# Server-side session handling backed by UserSession. The raw session key lives
# in an httponly cookie; only its hash (token) is stored in the database.
module Authentication
  extend ActiveSupport::Concern

  COOKIE_NAME = "user_session"

  included do
    helper_method :current_user, :current_session, :signed_in?
  end

  private

  def current_session
    return @current_session if defined?(@current_session)

    key = cookies[COOKIE_NAME]
    @current_session = key.present? ? UserSession.from_key(key) : nil
    # Clear a stale cookie whose session is gone/expired/revoked.
    cookies.delete(COOKIE_NAME) if key.present? && @current_session.nil?
    @current_session
  end

  def current_user
    current_session&.user
  end

  def signed_in?
    current_user.present?
  end

  # Create a fresh session for the user and set the session cookie.
  def login_user(user)
    key = UserSession.generate_session_key
    accessed_at = Time.current

    user.user_sessions.create!(
      token: key.token,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      accessed_at: accessed_at
    )

    set_session_cookie(key.key, expires_at: accessed_at + UserSession::SESSION_TIMEOUT)
    remove_instance_variable(:@current_session) if defined?(@current_session)
  end

  def logout
    current_session&.revoke(reason: :logout)
    cookies.delete(COOKIE_NAME)
    remove_instance_variable(:@current_session) if defined?(@current_session)
  end

  def set_session_cookie(value, expires_at:)
    cookies[COOKIE_NAME] = {
      value: value,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax,
      expires: expires_at
    }
  end

  def require_authentication
    return if signed_in?

    redirect_to root_path, alert: "Please sign in to continue."
  end
end
