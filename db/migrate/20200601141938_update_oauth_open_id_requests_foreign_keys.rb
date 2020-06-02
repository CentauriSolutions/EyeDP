class UpdateOauthOpenIdRequestsForeignKeys < ActiveRecord::Migration[6.0]
  # disable_ddl_transaction!

  def change
    # remove_foreign_key :users, column: :admin_id
    # add_foreign_key :users, :admins, column: :admin_id, on_delete: :nullify
    remove_foreign_key(
      :oauth_openid_requests,
      :oauth_access_grants,
      column: :access_grant_id)

    add_foreign_key(
      :oauth_openid_requests,
      :oauth_access_grants,
      column: :access_grant_id,
      on_delete: :cascade)
  end

  # def up
  #       # remove_foreign_key(:oauth_openid_requests, name: existing_foreign_key_name)

  # end

  # def down
  #   remove_foreign_key(
  #     :oauth_openid_requests,
  #     :oauth_access_grants,
  #     column: :access_grant_id,
  #     on_delete: :cascade)

  #   add_foreign_key(
  #     :oauth_openid_requests,
  #     :oauth_access_grants,
  #     column: :access_grant_id
  #   )
  #   # remove_foreign_key(:oauth_openid_requests, name: new_foreign_key_name)
  # end

  # private
end
