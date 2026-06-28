# frozen_string_literal: true

require "digest"
require "securerandom"

class UserSession < ApplicationRecord
  # Generated key byte size.
  KEY_SIZE = 32

  # Token should be a 44 character Base64 string (SHA256 digest, Base64 encoded).
  TOKEN_PATTERN = %r{\A[A-Za-z0-9+/=]{44}\z}

  # How long a session stays valid since it was last accessed.
  SESSION_TIMEOUT = 2.weeks
  # Throttle accessed_at writes so we don't write on every request.
  ACCESS_THROTTLING = 1.day
  # Throttle ip_address writes when the IP changes.
  IP_CHANGE_THROTTLING = 5.minutes

  GeneratedSessionKey = Data.define(:key, :token)

  belongs_to :user

  enum :revoked_reason, [ :logout, :password_changed, :session_revoked ]

  validates :token, presence: true, uniqueness: true, format: { with: TOKEN_PATTERN }
  validates :revoked_reason, presence: true, if: :revoked?
  validates :accessed_at, presence: true

  scope :active, -> {
    where(revoked_at: nil).where("accessed_at > ?", SESSION_TIMEOUT.ago)
  }

  # Generate a Base64 encoded SHA256 hash of a given session key.
  def self.token_for(key)
    Digest::SHA256.base64digest(key)
  end

  # Generate a session key and its hashed version. The raw key is handed to the
  # client; only the token (hash) is stored.
  def self.generate_session_key
    key = SecureRandom.urlsafe_base64(KEY_SIZE)
    GeneratedSessionKey.new(key: key, token: token_for(key))
  end

  # Look up an active session from a raw client key.
  def self.from_key(key)
    active.find_by(token: token_for(key))
  end

  def revoke(reason:)
    self.revoked_at = Time.current
    self.revoked_reason = reason
    save
  end

  def revoked?
    revoked_at.present?
  end

  def expired?
    accessed_at.nil? || accessed_at < SESSION_TIMEOUT.ago
  end

  def active?
    !revoked? && !expired?
  end

  # Touch accessed timestamp / request metadata to note the user accessed the
  # session. Writes are throttled to avoid a write on every page load:
  # - accessed_at: at most once per ACCESS_THROTTLING period.
  # - ip_address: at most once per IP_CHANGE_THROTTLING period when it changes.
  def access(request)
    return if new_record?

    assign_attributes_from_request(request)
    update_attributes_and_accessed_at if update_session_data?
  end

  private

  def assign_attributes_from_request(request)
    self.ip_address = request.remote_ip
    self.user_agent = request.user_agent
  end

  def update_session_data?
    accessed_at_needs_updating? || ip_needs_updating?
  end

  def accessed_at_needs_updating?
    (accessed_at.nil? || accessed_at < ACCESS_THROTTLING.ago) &&
      !Rails.cache.read(update_cache_key("accessed_at"))
  end

  def ip_needs_updating?
    ip_address_changed? &&
      updated_at <= IP_CHANGE_THROTTLING.ago &&
      !Rails.cache.read(update_cache_key("ip"))
  end

  def update_attributes_and_accessed_at
    if ip_address_changed?
      Rails.cache.write(update_cache_key("ip"), true, expires_in: IP_CHANGE_THROTTLING)
    end

    self.accessed_at = Time.current
    saved = save

    Rails.cache.write(update_cache_key("accessed_at"), true, expires_in: ACCESS_THROTTLING)

    saved
  end

  def update_cache_key(column)
    "v1:user_session:#{id}:update_#{column}"
  end
end
