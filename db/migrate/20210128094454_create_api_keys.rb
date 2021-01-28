class CreateApiKeys < ActiveRecord::Migration[6.1]
  def change
    create_table :api_keys, id: :uuid do |t|
      t.text :key, null: false
      t.text :name
      t.text :description
      t.integer :capabilities_mask, null: false, default: 0
      t.timestamps
    end
  end
end
