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

      t.boolean :user_create_events, default: false, nil: false
      t.boolean :user_update_events, default: false, nil: false
      t.boolean :user_destroy_events, default: false, nil: false

      t.boolean :group_create_events, default: false, nil: false
      t.boolean :group_update_events, default: false, nil: false
      t.boolean :group_destroy_events, default: false, nil: false

      t.boolean :group_membership_create_events, default: false, nil: false
      t.boolean :group_membership_destroy_events, default: false, nil: false

      t.timestamps
    end
  end
end
