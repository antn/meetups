# frozen_string_literal: true

class MeetupTag < ApplicationRecord
  belongs_to :meetup
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :meetup_id }
end
