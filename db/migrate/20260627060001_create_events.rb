class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string  :public_id, limit: 12, null: false, index: { unique: true }
      t.string  :name,      null: false
      t.string  :time_zone, null: false
      t.boolean :active,    null: false, default: false

      t.timestamps
    end

    # At most one active event at a time.
    add_index :events, :active, unique: true, where: "active", name: "index_events_on_single_active"
  end
end
