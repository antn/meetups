# frozen_string_literal: true

class Session < ApplicationRecord
  # Generated key byte size
  KEY_SIZE = 32

  # Hashed key should be a 44 character Base64 string
  HASHED_KEY_PATTERN = %r{\A[A-Za-z0-9+/=]{44}\z}

  DEFAULT_EXPIRATION = 2.weeks

  belongs_to :user

  scope :active, -> { where("expires_at > ?", Time.zone.now) }

  before_validation :set_initial_expiration

  # Public: Generate a Base64 encoded SHA256 hash of a given session key.
  #
  # key - The String key to hash.
  #
  # Returns a String.
  def self.hash_for(key)
    Digest::SHA256.base64digest(key)
  end

  # Public: Generate a session key and its hashed version.
  #
  # Returns a GeneratedSessionKey.
  def self.generate_session_key
    key = SecureRandom.urlsafe_base64(KEY_SIZE)
    GeneratedSessionKey.new(key: key, hashed_key: hash_for(key))
  end

  # Public: Looks up a session for a given session key.
  #
  # key - The String unhashed key.
  #
  # Returns a UserSession|nil.
  def self.from_key(key)
    hashed_key = hash_for(key)
    Session.active.find_by(hashed_key: hashed_key)
  end

  # Public: The expiration date of a session from now, used for setting cookie
  #         expiration etc.
  #
  # Returns a Time.
  def expiration_date_from_now
    DEFAULT_EXPIRATION.from_now.utc
  end

  class GeneratedSessionKey
    attr_reader :key
    attr_reader :hashed_key

    # key - A String plaintext session key.
    # hashed_key - A String hash of the plaintext session key.
    def initialize(key:, hashed_key:)
      @key        = key
      @hashed_key = hashed_key
    end
  end

  private

  def set_initial_expiration
    return if expires_at.present?
    self.expires_at = expiration_date_from_now
  end
end
