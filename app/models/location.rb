# frozen_string_literal: true

class Location < ApplicationRecord
  ALLOWED_MAP_IMAGE_TYPES = %w[image/png image/jpeg image/webp].freeze
  MAX_MAP_IMAGE_SIZE = 1.megabyte

  belongs_to :event
  has_many :meetups, dependent: :restrict_with_error
  has_many :blocked_hours, class_name: "LocationBlockedHour", dependent: :destroy

  # Map showing where in the venue this location is. Shown on the meetup page.
  has_one_attached :map_image

  validates :name,
    presence: true,
    uniqueness: { scope: :event_id, case_sensitive: false }
  validate :map_image_is_a_supported_image

  scope :active, -> { where(active: true) }

  # Whether this location is blocked for the hour beginning at `starts_at`
  # (an absolute instant) on the given scheduling day.
  def blocked_at?(scheduling_day, starts_at)
    return false if scheduling_day.blank? || starts_at.blank?

    hour = starts_at.in_time_zone(event.tz).hour
    blocked_hours.exists?(scheduling_day: scheduling_day, hour: hour)
  end

  # Visible meetups occupying an hour that is now blocked (booked before the
  # block was added). They stay scheduled; blocking only stops new bookings.
  def meetups_in_blocked_hours
    blocked = blocked_hours.pluck(:scheduling_day_id, :hour).to_set
    return [] if blocked.empty?

    zone = event.tz
    meetups.visible.select do |meetup|
      blocked.include?([ meetup.scheduling_day_id, meetup.starts_at.in_time_zone(zone).hour ])
    end
  end

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
