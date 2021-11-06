class CreateEmails < ActiveRecord::Migration[6.1]
  def up
    create_table :emails, id: :uuid do |t|
      t.uuid :user_id
      t.string :address
      t.boolean :primary, default: false, index: true

      ## Confirmable
      t.string :unconfirmed_email
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at

      t.timestamps
    end
    add_index :emails, :address, unique: true
    execute 'INSERT INTO emails (address, user_id, "primary", created_at, updated_at, confirmed_at) (SELECT email, id, true, NOW(), NOW(), NOW() FROM users);'
    remove_column :users, :email
  end

  def down
    add_column :users, :email, :text
    execute 'update users set email = (select address from emails where "primary"=true and user_id = users.id);'
    drop_table :emails
  end
end
