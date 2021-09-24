class AddCustomDataToApiKey < ActiveRecord::Migration[6.1]
  def change
    add_column :api_keys, :custom_data, :text, array: true
  end
end
