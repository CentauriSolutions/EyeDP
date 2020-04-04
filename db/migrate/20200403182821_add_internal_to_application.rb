class AddInternalToApplication < ActiveRecord::Migration[6.0]
  def change
    add_column :oauth_applications, :internal, :bool, default: false
  end
end
