class AddRealNameToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :name, :text
  end
end
