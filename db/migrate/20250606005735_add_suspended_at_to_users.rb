# frozen_string_literal: true

class AddSuspendedAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :suspended_at, :datetime
    add_index :users, :suspended_at
  end
end
