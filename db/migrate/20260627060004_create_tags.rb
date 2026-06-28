class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.string     :public_id, limit: 12, null: false, index: { unique: true }
      t.references :event, null: false, foreign_key: true
      t.string     :name, null: false

      t.timestamps
    end

    add_index :tags, [ :event_id, :name ], unique: true
  end
end
