# frozen_string_literal: true

class Location < ApplicationRecord
  ALLOWED_MAP_IMAGE_TYPES = %w[image/png image/jpeg image/webp].freeze
  MAX_MAP_IMAGE_SIZE = 1.megabyte

  belongs_to :event
  has_many :meetups, dependent: :restrict_with_error

  # Map showing where in the venue this location is. Shown on the meetup page.
  has_one_attached :map_image

  validates :name,
    presence: true,
    uniqueness: { scope: :event_id, case_sensitive: false }
  validate :map_image_is_a_supported_image

  scope :active, -> { where(active: true) }

  private

  def map_image_is_a_supported_image
    return unless map_image.attached?

    unless map_image.blob.content_type.in?(ALLOWED_MAP_IMAGE_TYPES)
      errors.add(:map_image, "must be a PNG, JPEG, or WebP image")
    end

    if map_image.blob.byte_size > MAX_MAP_IMAGE_SIZE
      errors.add(:map_image, "must be smaller than 1 MB")
    end
  end
end
