class CreateMeetupTags < ActiveRecord::Migration[8.1]
  def change
    create_table :meetup_tags do |t|
      t.string     :public_id, limit: 12, null: false, index: { unique: true }
      t.references :meetup, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :meetup_tags, [ :meetup_id, :tag_id ], unique: true
  end
end
