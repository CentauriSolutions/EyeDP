class AddDisabledAtToUser < ActiveRecord::Migration[6.1]
  def up
    add_column :users, :disabled_at, :timestamp
    execute "UPDATE users SET disabled_at = expires_at WHERE expires_at IS NOT NULL"
  end

  def down
    remove_column :users, :disabled_at
  end
end
