# frozen_string_literal: true

class User < ApplicationRecord
  # Find or create the user behind an OmniAuth callback (Concat provider), keeping
  # their login/email in sync with the identity provider.
  def self.from_omniauth(auth)
    user = find_or_initialize_by(uid: auth.uid)
    user.login = auth.info.username.presence || auth.info.name.presence || user.login || "user-#{auth.uid}"
    user.email = auth.info.email.presence || user.email
    user.profile_picture_url = auth.info.image.presence || user.profile_picture_url
    user.save!
    user
  end

  # Single-field staff search: partial, case-insensitive login match, or an exact
  # match on the external uid (numeric) or the public_id.
  def self.search(query)
    query = query.to_s.strip
    return all if query.blank?

    if query.match?(/\A\d+\z/)
      where("login ILIKE ? OR public_id = ? OR uid = ?", "%#{query}%", query, query.to_i)
    else
      where("login ILIKE ? OR public_id = ?", "%#{query}%", query)
    end
  end

  def suspended?
    suspended_at.present?
  end

  # Suspend the account: flag it (which blocks future logins, see
  # SessionsController#create) and revoke any live sessions so they're booted now.
  def suspend!
    transaction do
      update!(suspended_at: Time.current)
      user_sessions.active.find_each { |session| session.revoke(reason: :session_revoked) }
    end
  end

  def unsuspend!
    update!(suspended_at: nil)
  end

  # Deep link into the OffKai Expo reg system's housekeeping view for this user.
  def housekeeping_url
    "https://reg.offkaiexpo.com/housekeeping/attendees/user/#{uid}"
  end

  has_many :user_sessions, dependent: :destroy
  has_many :meetups, dependent: :restrict_with_error
  has_many :attendances, dependent: :destroy
  has_many :attending_meetups, through: :attendances, source: :meetup
  has_many :reviewed_meetups,
    class_name: "Meetup",
    foreign_key: :reviewed_by_id,
    dependent: :nullify,
    inverse_of: :reviewed_by
end
