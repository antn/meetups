# frozen_string_literal: true

class SessionsController < ApplicationController
  # The OmniAuth callback arrives without our CSRF token (the provider initiates
  # it); the request phase (POST /auth/:provider) is what carries CSRF protection.
  skip_before_action :verify_authenticity_token, only: :create, raise: false

  # OmniAuth callback: /auth/:provider/callback
  def create
    auth = request.env["omniauth.auth"]
    return redirect_to(root_path, alert: "Sign in failed. Please try again.") if auth.blank?

    user = User.from_omniauth(auth)

    if user.suspended?
      redirect_to root_path, alert: "Your account has been suspended. Please contact events@offkaiexpo.com."
    else
      login_user(user)
      redirect_to root_path, notice: "Signed in as #{user.login}."
    end
  end

  def destroy
    logout
    redirect_to root_path, notice: "You have been signed out."
  end

  # OmniAuth failure redirect: /auth/failure
  def failure
    redirect_to root_path, alert: "Sign in failed: #{params[:message].presence || 'unknown error'}."
  end
end
