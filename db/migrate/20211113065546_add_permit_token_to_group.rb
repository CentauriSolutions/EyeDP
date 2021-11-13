class AddPermitTokenToGroup < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :permit_token, :boolean, default: false
  end
end
