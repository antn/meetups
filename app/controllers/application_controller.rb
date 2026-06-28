class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :track_session

  private

  # Refresh the session's last-accessed timestamp (throttled in the model).
  def track_session
    current_session&.access(request)
  end
end
