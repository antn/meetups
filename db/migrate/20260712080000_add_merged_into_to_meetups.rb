# frozen_string_literal: true

class AddMergedIntoToMeetups < ActiveRecord::Migration[8.1]
  def change
    # When a moderator merges one meetup into another, the source is cancelled
    # and this records where its RSVPs went — used to suppress the standard
    # cancellation email and to redirect the old public URL to the target.
    add_reference :meetups, :merged_into, foreign_key: { to_table: :meetups }
  end
end
