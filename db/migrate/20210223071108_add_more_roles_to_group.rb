class AddMoreRolesToGroup < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :manager, :boolean, default: false
    add_column :groups, :operator, :boolean, default: false
  end
end
