class CreateGroupPermissions < ActiveRecord::Migration[5.2]
  def change
    create_table :group_permissions, id: :uuid do |t|
      t.references :group, foreign_key: true
      t.references :permission, foreign_key: true

      t.timestamps
    end
  end
end
