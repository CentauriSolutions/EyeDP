class CreateCustomUserdataTypes < ActiveRecord::Migration[6.0]
  def change
    create_table :custom_userdata_types, id: :uuid do |t|
      t.text :name
      t.text :custom_type
      t.boolean :visible, default: true

      t.timestamps
    end
  end
end
