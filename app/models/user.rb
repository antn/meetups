# frozen_string_literal: true

class User < ApplicationRecord
  validates :uid, presence: true, uniqueness: true
  validates :login, :email, presence: true

  has_many :sessions, dependent: :destroy

  def self.from_omniauth(auth)
    where(uid: auth.uid).first_or_initialize.tap do |user|
      user.login = auth.info.username
      user.email = auth.info.email
      user.save!
    end
  end

  def suspend!
    update!(suspended_at: Time.now)
    sessions.active.each do |session|
      session.update!(expires_at: Time.now)
    end
  end

  def suspended?
    suspended_at.present?
  end

  def housekeeping_url
    "https://reg.offkaiexpo.com/housekeeping/attendees/user/#{uid}"
  end
end
