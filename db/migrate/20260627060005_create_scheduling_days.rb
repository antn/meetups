class CreateSchedulingDays < ActiveRecord::Migration[8.1]
  def change
    create_table :scheduling_days do |t|
      t.string     :public_id, limit: 12, null: false, index: { unique: true }
      t.references :event, null: false, foreign_key: true
      t.date       :date, null: false
      t.time       :start_time, null: false
      t.time       :end_time, null: false

      t.timestamps
    end

    add_index :scheduling_days, [ :event_id, :date ], unique: true
  end
end
