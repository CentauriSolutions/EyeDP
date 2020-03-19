class AddAuthTypeToLogin < ActiveRecord::Migration[6.0]
  def change
    add_column :logins, :auth_type, :text, default: 'New Login'
  end
end
