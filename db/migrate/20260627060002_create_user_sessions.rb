class CreateUserSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :user_sessions do |t|
      t.string     :public_id, limit: 12, null: false, index: { unique: true }
      t.references :user, null: false, foreign_key: true
      t.binary     :token, limit: 44, null: false
      t.string     :ip_address, limit: 60
      t.string     :user_agent
      t.datetime   :accessed_at
      t.datetime   :revoked_at
      t.integer    :revoked_reason

      t.timestamps
    end

    add_index :user_sessions, :token, unique: true
    add_index :user_sessions, :ip_address
    add_index :user_sessions, [ :token, :revoked_at ]
    add_index :user_sessions, [ :user_id, :revoked_at ]
  end
end
