class AddUniqueConstraintsToCustomTypes < ActiveRecord::Migration[6.0]
  def change
    add_index :custom_userdata, [ :user_id, :custom_userdata_type_id ], :unique => true, name: :custom_userdata_unique
    add_index :custom_groupdata, [ :group_id, :custom_group_data_type_id ], :unique => true, name: :custom_groupdata_unique
  end
end
