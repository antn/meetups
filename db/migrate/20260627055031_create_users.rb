class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string   :public_id, limit: 12, null: false, index: { unique: true }
      t.integer  :uid,        null: false, index: { unique: true }
      t.string   :login,      null: false, index: { unique: true }
      t.string   :email,      null: false, index: { unique: true }
      t.boolean  :site_admin, null: false, default: false
      t.datetime :suspended_at

      t.timestamps
    end
  end
end
