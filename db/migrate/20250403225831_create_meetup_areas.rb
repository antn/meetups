class CreateMeetupAreas < ActiveRecord::Migration[8.0]
  def change
    create_table :meetup_areas do |t|
      t.string :name, null: false
      t.string :location
      t.text :description

      t.timestamps
    end
  end
end
