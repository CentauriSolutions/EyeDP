class CreateCustomGroupDataTypes < ActiveRecord::Migration[6.0]
  def change
    create_table :custom_group_data_types, id: :uuid do |t|
      t.text :name
      t.text :custom_type

      t.timestamps
    end
  end
end
