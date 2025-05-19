# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_session&.user
  end
  helper_method :current_user

  def current_session
    return @current_session if defined?(@current_session)
    return @current_session = nil unless cookies[SessionsController::COOKIE_NAME].present?

    session = Session.from_key(cookies[SessionsController::COOKIE_NAME])

    # If the session has since expired or is otherwise non-existent, clear
    # the user's current cookie
    cookies.delete(SessionsController::COOKIE_NAME) if session.blank?

    @current_session = session
  end

  def require_logged_in
    return if current_user.present?
    flash[:notice] = "You must login before doing that."
    return redirect_to root_url
  end

  def render_404
    if request.format.try(:html?)
      render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found
    elsif request.format.try(:json?)
      render json: { error: "Not Found" }, status: :not_found
    else
      render plain: "Not Found", status: :not_found
    end
  end
end
