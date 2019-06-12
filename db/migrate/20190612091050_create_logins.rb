class CreateLogins < ActiveRecord::Migration[5.2]
  def change
    create_table :logins, id: :uuid do |t|
      t.references :user, foreign_key: true, type: :uuid
      t.references :service_provider, polymorphic: true, type: :uuid

      t.timestamps
    end
  end
end
