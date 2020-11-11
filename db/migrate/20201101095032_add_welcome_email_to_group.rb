class AddWelcomeEmailToGroup < ActiveRecord::Migration[6.0]
  def change
    add_column :groups, :welcome_email, :text
  end
end
