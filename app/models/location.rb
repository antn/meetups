# frozen_string_literal: true

class Location < ApplicationRecord
  belongs_to :event
  has_many :meetups, dependent: :restrict_with_error

  validates :name,
    presence: true,
    uniqueness: { scope: :event_id, case_sensitive: false }

  scope :active, -> { where(active: true) }
end
