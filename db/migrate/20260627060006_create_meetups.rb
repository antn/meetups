class CreateMeetups < ActiveRecord::Migration[8.1]
  def change
    create_table :meetups do |t|
      t.string     :public_id, limit: 12, null: false, index: { unique: true }
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :location, null: false, foreign_key: true
      t.references :scheduling_day, null: false, foreign_key: true
      t.datetime   :starts_at, null: false
      t.string     :title, null: false
      t.text       :description
      t.integer    :status, null: false, default: 0
      t.bigint     :reviewed_by_id
      t.datetime   :reviewed_at
      t.text       :rejection_reason

      t.timestamps
    end

    add_index :meetups, :status
    add_index :meetups, :starts_at
    add_index :meetups, :reviewed_by_id
    add_foreign_key :meetups, :users, column: :reviewed_by_id

    # At most one non-rejected (pending or approved) meetup per location + timeslot.
    # status: pending = 0, approved = 1, rejected = 2 -> "status <> 2" excludes rejected.
    add_index :meetups, [ :location_id, :starts_at ],
              unique: true,
              where: "status <> 2",
              name: "index_meetups_unique_active_slot"
  end
end
