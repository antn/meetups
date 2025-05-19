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

  def housekeeping_url
    "https://reg.offkaiexpo.com/housekeeping/attendees/user/#{uid}"
  end
end
