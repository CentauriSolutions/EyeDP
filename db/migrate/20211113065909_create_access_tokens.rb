class CreateAccessTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :access_tokens, id: :uuid do |t|
      t.text :token, null: false
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.text :name
      t.date :expires_at
      t.datetime :last_used_at

      t.timestamps
    end
  end
end
