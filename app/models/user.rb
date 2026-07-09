# frozen_string_literal: true

class User < ApplicationRecord
  # Find or create the user behind an OmniAuth callback (Concat provider), keeping
  # their login/email in sync with the identity provider.
  #
  # The provider owns logins/emails, but we only re-sync a user's row when they
  # log in — so a row can hold a login/email its owner has since given up on the
  # provider, blocking whoever claimed it there. Park such stale rows on
  # placeholders before saving; their real values re-sync on their next login.
  def self.from_omniauth(auth)
    transaction do
      user = find_or_initialize_by(uid: auth.uid)
      user.login = auth.info.username.presence || auth.info.name.presence || user.login || "user-#{auth.uid}"
      user.email = auth.info.email.presence || user.email
      user.profile_picture_url = auth.info.image.presence || user.profile_picture_url
      release_stale_claims!(user)
      user.save!
      user
    end
  end

  # If another row (different uid) holds `user`'s incoming login or email, that
  # row is provably stale — rename it so the unique indexes accept the save.
  def self.release_stale_claims!(user)
    if user.will_save_change_to_login? && (stale = where(login: user.login).where.not(uid: user.uid).first)
      stale.update!(login: placeholder_login_for(stale))
    end
    if user.will_save_change_to_email? && (stale = where(email: user.email).where.not(uid: user.uid).first)
      stale.update!(email: placeholder_email_for(stale))
    end
  end
  private_class_method :release_stale_claims!

  # "user-<uid>" mirrors the blank-username fallback in from_omniauth. A real
  # provider user could legitimately register that name, so probe until free.
  def self.placeholder_login_for(stale)
    candidate = "user-#{stale.uid}"
    candidate = "user-#{stale.uid}-#{SecureRandom.hex(4)}" while where(login: candidate).where.not(id: stale.id).exists?
    candidate
  end
  private_class_method :placeholder_login_for

  # ".invalid" is an RFC 2606 reserved TLD, so this never collides with a real
  # provider-issued address — only with a previously parked one.
  def self.placeholder_email_for(stale)
    candidate = "user-#{stale.uid}@stale.invalid"
    candidate = "user-#{stale.uid}-#{SecureRandom.hex(4)}@stale.invalid" while where(email: candidate).where.not(id: stale.id).exists?
    candidate
  end
  private_class_method :placeholder_email_for

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
