# frozen_string_literal: true

module Stafftools
  # Base controller for the admin area. Every action is gated on site_admin and
  # rendered in the dedicated stafftools layout. Most tooling is scoped to the
  # single active event, exposed as `current_event`.
  class ApplicationController < ::ApplicationController
    layout "stafftools"

    before_action :require_admin

    helper_method :current_event

    private

    # Non-admins get a 404 rather than a redirect, so the stafftools area is
    # indistinguishable from a nonexistent route to anyone without access.
    def require_admin
      return if current_user&.site_admin?

      raise ActionController::RoutingError, "Not Found"
    end

    def current_event
      @current_event ||= Event.current
    end

    # Resource controllers that operate on event-scoped records bail out early
    # when no event is accepting meetups, so they never NoMethodError on nil.
    def require_current_event
      return if current_event.present?

      redirect_to stafftools_root_path, alert: "There is no active event to manage yet."
    end
  end
end
