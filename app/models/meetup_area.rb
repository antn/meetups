# frozen_string_literal: true

class MeetupArea < ApplicationRecord
  validates :name, presence: true

  has_many :meetups, dependent: :destroy
  has_many :meetup_days
end
