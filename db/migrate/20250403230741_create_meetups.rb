class CreateMeetups < ActiveRecord::Migration[8.0]
  def change
    create_table :meetups do |t|
      t.string :name, null: false, index: true
      t.text :description, null: false
      t.datetime :starts_at
      t.datetime :ends_at
      t.integer :user_id, null: false
      t.integer :state, null: false, default: 0, index: true
      t.integer :meetup_area_id, index: true
      t.integer :meetup_day_id, index: true

      t.timestamps
    end
  end
end
