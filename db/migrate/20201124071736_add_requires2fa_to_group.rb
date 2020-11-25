class AddRequires2faToGroup < ActiveRecord::Migration[6.0]
  def change
    add_column :groups, :requires_2fa, :boolean, default: false
  end
end
