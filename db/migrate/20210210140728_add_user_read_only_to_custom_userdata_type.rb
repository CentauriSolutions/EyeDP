class AddUserReadOnlyToCustomUserdataType < ActiveRecord::Migration[6.1]
  def change
    add_column :custom_userdata_types, :user_read_only, :bool, default: false
  end
end
