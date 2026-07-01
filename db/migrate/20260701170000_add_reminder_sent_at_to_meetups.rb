# frozen_string_literal: true

class AddReminderSentAtToMeetups < ActiveRecord::Migration[8.1]
  def change
    add_column :meetups, :reminder_sent_at, :datetime

    # The reminder sweep scans for approved, not-yet-reminded meetups starting
    # within the lead window. A partial index over just those rows keeps that
    # frequent query cheap as the table grows.
    add_index :meetups, :starts_at,
      name: "index_meetups_pending_reminder",
      where: "reminder_sent_at IS NULL AND status = 1"
  end
end
