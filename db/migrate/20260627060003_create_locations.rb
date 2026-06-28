class CreateLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :locations do |t|
      t.string     :public_id, limit: 12, null: false, index: { unique: true }
      t.references :event, null: false, foreign_key: true
      t.string     :name, null: false
      t.text       :description
      t.boolean    :active, null: false, default: true

      t.timestamps
    end

    add_index :locations, [ :event_id, :name ], unique: true
  end
end
