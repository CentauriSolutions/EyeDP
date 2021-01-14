class CreateCustomUserdata < ActiveRecord::Migration[6.0]
  def change
    create_table :custom_userdata, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :custom_userdata_type, null: false, foreign_key: true, type: :uuid
      t.text :value_raw

      t.timestamps
    end
  end
end
