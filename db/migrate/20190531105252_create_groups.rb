class CreateGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :groups, id: :uuid do |t|
      t.references :parent, index: true, type: :uuid, references: :groups
      t.text :name

      t.timestamps
    end
  end
end
