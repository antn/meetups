# frozen_string_literal: true

class Tag < ApplicationRecord
  # Selectable chip colors, drawn from the brand palette in application.tailwind.css.
  COLORS = %w[purple pink blue yellow orange].freeze

  belongs_to :event
  has_many :meetup_tags, dependent: :destroy
  has_many :meetups, through: :meetup_tags

  validates :name,
    presence: true,
    uniqueness: { scope: :event_id, case_sensitive: false }
  validates :color, inclusion: { in: COLORS }
end
