# frozen_string_literal: true

# A user's RSVP to a meetup. At most one per (user, meetup).
class Attendance < ApplicationRecord
  belongs_to :user
  belongs_to :meetup

  validates :meetup_id, uniqueness: { scope: :user_id }
end
