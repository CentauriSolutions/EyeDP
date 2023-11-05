class AddWebauthnIdToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :webauthn_id, :text
  end
end
