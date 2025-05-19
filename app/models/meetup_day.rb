# frozen_string_literal: true

class MeetupDay < ApplicationRecord
  has_many :meetups
  has_many :non_rejected_meetups, -> { where.not(state: :rejected) }, class_name: "Meetup"

  validates :starts_at, :ends_at, presence: true
  validate :validate_same_day
  validate :validate_unique_date
  validate :validate_whole_hours
  validate :validate_ends_after_starts

  def date_in_local_time
    starts_at.in_time_zone("Pacific Time (US & Canada)").to_date
  end

  private

  def validate_same_day
    if starts_at.present? && ends_at.present?
      pacific_starts_at = starts_at.in_time_zone("Pacific Time (US & Canada)")
      pacific_ends_at = ends_at.in_time_zone("Pacific Time (US & Canada)")

      if pacific_starts_at.to_date != pacific_ends_at.to_date
        errors.add(:ends_at, "must be on the same day as starts_at in Pacific Time")
      end
    end
  end

  def validate_unique_date
    if starts_at.present? && ends_at.present?
      pacific_starts_at = starts_at.in_time_zone("America/Los_Angeles").to_date
      pacific_ends_at = ends_at.in_time_zone("America/Los_Angeles").to_date

      overlapping_days = MeetupDay.where.not(id: id).where(
        "DATE(starts_at AT TIME ZONE 'UTC' AT TIME ZONE 'America/Los_Angeles') = ? OR
         DATE(ends_at AT TIME ZONE 'UTC' AT TIME ZONE 'America/Los_Angeles') = ?",
        pacific_starts_at, pacific_ends_at
      )

      if overlapping_days.exists?
        errors.add(:starts_at, "is already a date that exists in Pacific Time")
      end
    end
  end

  def validate_whole_hours
    if starts_at.present? && starts_at.min != 0
      errors.add(:starts_at, "must be set to a whole hour (no minutes)")
    end

    if ends_at.present? && ends_at.min != 0
      errors.add(:ends_at, "must be set to a whole hour (no minutes)")
    end
  end

  def validate_ends_after_starts
    if starts_at.present? && ends_at.present? && ends_at <= starts_at
      errors.add(:ends_at, "must be after starts_at")
    end
  end
end
