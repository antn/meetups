# frozen_string_literal: true

module Stafftools
  class UsersController < ApplicationController
    before_action :set_user, only: %i[suspend unsuspend]

    def index
      @query = params[:q].to_s.strip
      @users = User.search(@query).order(:login)
    end

    def suspend
      if @user.site_admin?
        redirect_back_to_users alert: "Site admins can't be suspended."
      else
        @user.suspend!
        redirect_back_to_users notice: "#{@user.login} has been suspended."
      end
    end

    def unsuspend
      @user.unsuspend!
      redirect_back_to_users notice: "#{@user.login}'s suspension was lifted."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    # Return to wherever the action was triggered (e.g. a meetup detail page),
    # falling back to the users list (preserving any active search).
    def redirect_back_to_users(flash)
      redirect_back fallback_location: stafftools_users_path(q: params[:q]), **flash
    end
  end
end
