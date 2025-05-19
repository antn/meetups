class CreateMeetupDays < ActiveRecord::Migration[8.0]
  def change
    create_table :meetup_days do |t|
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false

      t.timestamps
    end
  end
end
