class CreateSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :sessions do |t|
      t.integer :user_id
      t.string :hashed_key
      t.datetime :expires_at

      t.timestamps
    end
  end
end
