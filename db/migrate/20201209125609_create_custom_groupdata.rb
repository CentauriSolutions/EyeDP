class CreateCustomGroupdata < ActiveRecord::Migration[6.0]
  def change
    create_table :custom_groupdata, id: :uuid do |t|
      t.references :group, null: false, foreign_key: true, type: :uuid
      t.references :custom_group_data_type, null: false, foreign_key: true, type: :uuid
      t.text :value_raw

      t.timestamps
    end
  end
end
