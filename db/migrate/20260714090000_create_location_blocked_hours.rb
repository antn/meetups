# frozen_string_literal: true

class CreateLocationBlockedHours < ActiveRecord::Migration[8.1]
  def change
    # An hour of a scheduling day during which a location can't be booked.
    # Stored as day + hour-of-day (not an absolute instant) so rows stay
    # meaningful if a day's date is later edited; hours outside the day's
    # current window are simply ignored at read time.
    create_table :location_blocked_hours do |t|
      t.references :location, null: false, foreign_key: true
      t.references :scheduling_day, null: false, foreign_key: true
      t.integer :hour, null: false
      t.string :public_id, limit: 12, null: false

      t.timestamps

      t.index [ :location_id, :scheduling_day_id, :hour ],
        unique: true,
        name: "index_location_blocked_hours_unique_slot"
      t.index :public_id, unique: true
    end
  end
end
