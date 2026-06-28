# frozen_string_literal: true

class Event < ApplicationRecord
  has_many :scheduling_days, dependent: :restrict_with_error
  has_many :locations, dependent: :restrict_with_error
  has_many :tags, dependent: :restrict_with_error
  has_many :meetups, dependent: :restrict_with_error

  validates :name, presence: true
  validates :time_zone, presence: true
  validate :time_zone_is_recognized

  # The single event currently accepting meetups, if any.
  def self.current
    find_by(active: true)
  end

  # Make this the active event, deactivating any other active event.
  def activate!
    transaction do
      Event.where.not(id: id).where(active: true).update_all(active: false)
      update!(active: true)
    end
  end

  # ActiveSupport::TimeZone used to interpret this event's scheduling days/times.
  # Accepts both Rails friendly names ("Pacific Time (US & Canada)") and IANA
  # identifiers ("America/Los_Angeles").
  def tz
    ActiveSupport::TimeZone[time_zone]
  end

  private

  def time_zone_is_recognized
    return if time_zone.blank?

    errors.add(:time_zone, "is not a recognized time zone") if tz.nil?
  end
end
