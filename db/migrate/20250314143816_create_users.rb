class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :uid, null: false, index: true
      t.string :login, null: false, index: true
      t.string :email, null: false, index: true
      t.boolean :site_admin, null: false, default: false

      t.timestamps
    end
  end
end
