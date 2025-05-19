# frozen_string_literal: true

class Meetup < ApplicationRecord
  belongs_to :user
  belongs_to :meetup_area, optional: true
  belongs_to :meetup_day, optional: true

  validates :name, presence: true, length: { minimum: 3, maximum: 50 }
  validates :description, presence: true, length: { minimum: 15, maximum: 280 }
  validates :starts_at, :ends_at, presence: true
  validate :no_duplicate_meetup_in_area, on: :create
  validate :validate_whole_hours
  validate :validate_ends_after_starts

  enum :state, [:pending, :approved, :rejected]

  def adminable_by?(actor)
    return false unless actor.present?
    return true if actor.site_admin?
    actor == user
  end

  private

  def no_duplicate_meetup_in_area
    return if meetup_area_id.nil? || starts_at.nil? || ends_at.nil?

    conflict = Meetup.where(
      meetup_area_id: meetup_area_id,
      starts_at: starts_at,
      ends_at: ends_at
    ).where.not(state: :rejected).exists?

    if conflict
      errors.add(:starts_at, "A meetup already exists for this area and time slot.")
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
