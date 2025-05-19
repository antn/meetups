# frozen_string_literal: true

class SessionsController < ApplicationController
  COOKIE_NAME = :user_session

  def create
    auth = request.env["omniauth.auth"]
    user = User.from_omniauth(auth)
    login_user(user)
    redirect_to root_path
  end

  def destroy
    current_session.destroy if current_session
    cookies.delete(COOKIE_NAME)
    redirect_to root_path
  end

  private

  def login_user(user)
    session_key = Session.generate_session_key
    session = user.sessions.build(hashed_key: session_key.hashed_key)
    session.save!

    cookies[COOKIE_NAME] = {
      value: session_key.key,
      expires: session.expiration_date_from_now,
      httponly: true,
    }
  end
end
