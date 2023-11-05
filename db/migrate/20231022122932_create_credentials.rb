class CreateCredentials < ActiveRecord::Migration[6.1]
  def change
    create_table :credentials, id: :uuid do |t|
      t.text :external_id
      t.text :public_key
      t.text :nickname
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.datetime :last_authenticated_at, null: false
      t.bigint :sign_count, null: false, default: 0

      t.timestamps
    end
    add_index :credentials, :external_id, unique: true
  end
end
