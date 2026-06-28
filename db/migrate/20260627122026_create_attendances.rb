class CreateAttendances < ActiveRecord::Migration[8.1]
  def change
    create_table :attendances do |t|
      t.references :user, null: false, foreign_key: true
      t.references :meetup, null: false, foreign_key: true
      t.string :public_id, limit: 12, null: false

      t.timestamps
    end

    add_index :attendances, %i[user_id meetup_id], unique: true
    add_index :attendances, :public_id, unique: true
  end
end
