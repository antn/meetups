# frozen_string_literal: true

require "nanoid"

module PublicIdGenerator
  extend ActiveSupport::Concern

  included do
    before_create :set_public_id
  end

  PUBLIC_ID_ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyz"
  PUBLIC_ID_LENGTH = 12
  MAX_RETRY = 1000

  class_methods do
    def generate_nanoid(alphabet: PUBLIC_ID_ALPHABET, size: PUBLIC_ID_LENGTH)
      Nanoid.generate(size: size, alphabet: alphabet)
    end
  end

  # Generates a random string for us as the public ID.
  def set_public_id
    return if public_id.present?

    MAX_RETRY.times do
      self.public_id = generate_public_id
      return unless self.class.where(public_id: public_id).exists?
    end

    raise "Failed to generate a unique public id after #{MAX_RETRY} attempts"
  end

  def generate_public_id
    self.class.generate_nanoid(alphabet: PUBLIC_ID_ALPHABET)
  end
end
