class AddAdminFieldToGroups < ActiveRecord::Migration[6.0]
  def up
    transaction do
      add_column :groups, :admin, :boolean, default: false
      Group.where(name: 'administrators').update({ admin: true })
    end
  end

  def down
    remove_column :groups, :admin, :boolean, default: false
  end
end
