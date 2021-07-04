class CreateWebhooks < ActiveRecord::Migration[6.1]
  def change
    create_table :web_hooks, id: :uuid do |t|
      t.json :headers
      t.json :template

      t.text :encrypted_url, nil: false
      t.text :encrypted_url_iv, nil: false, unique: true
      t.text :encrypted_token, nil: false
      t.text :encrypted_token_iv, nil: false, unique: true
      t.boolean :enable_ssl_verification, default: true, nil: false

      t.integer :recent_failures, default: 0, nil: false, limit: 2
      t.integer :backoff_count, default: 0, nil: false, limit: 2
      t.timestamp :disabled_until

      t.boolean :user_created_events, default: false, nil: false
      t.boolean :user_updated_events, default: false, nil: false
      t.boolean :user_deleted_events, default: false, nil: false

      t.boolean :group_created_events, default: false, nil: false
      t.boolean :group_updated_events, default: false, nil: false
      t.boolean :group_deleted_events, default: false, nil: false

      t.boolean :group_membership_created_events, default: false, nil: false
      t.boolean :group_membership_deleted_events, default: false, nil: false

      t.timestamps
    end
  end
end
