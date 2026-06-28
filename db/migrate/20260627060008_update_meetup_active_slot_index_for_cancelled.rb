class UpdateMeetupActiveSlotIndexForCancelled < ActiveRecord::Migration[8.1]
  def up
    remove_index :meetups, name: "index_meetups_unique_active_slot"

    # Both rejected (2) and cancelled (3) free the slot; only pending/approved hold it.
    add_index :meetups, [ :location_id, :starts_at ],
              unique: true,
              where: "status NOT IN (2, 3)",
              name: "index_meetups_unique_active_slot"
  end

  def down
    remove_index :meetups, name: "index_meetups_unique_active_slot"

    add_index :meetups, [ :location_id, :starts_at ],
              unique: true,
              where: "status <> 2",
              name: "index_meetups_unique_active_slot"
  end
end
