# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_07_04_060019) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "audits", force: :cascade do |t|
    t.uuid "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.uuid "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "custom_group_data_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "name"
    t.text "custom_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "custom_groupdata", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "group_id", null: false
    t.uuid "custom_group_data_type_id", null: false
    t.text "value_raw"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["custom_group_data_type_id"], name: "index_custom_groupdata_on_custom_group_data_type_id"
    t.index ["group_id", "custom_group_data_type_id"], name: "custom_groupdata_unique", unique: true
    t.index ["group_id"], name: "index_custom_groupdata_on_group_id"
  end

  create_table "custom_userdata", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "custom_userdata_type_id", null: false
    t.text "value_raw"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["custom_userdata_type_id"], name: "index_custom_userdata_on_custom_userdata_type_id"
    t.index ["user_id", "custom_userdata_type_id"], name: "custom_userdata_unique", unique: true
    t.index ["user_id"], name: "index_custom_userdata_on_user_id"
  end

  create_table "custom_userdata_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "name"
    t.text "custom_type"
    t.boolean "visible", default: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "user_read_only", default: false
  end

  create_table "fido_usf_devices", force: :cascade do |t|
    t.string "user_type", null: false
    t.uuid "user_id", null: false
    t.string "name", default: "", null: false
    t.string "key_handle", limit: 255, default: "", null: false
    t.binary "public_key", null: false
    t.binary "certificate", null: false
    t.integer "counter", default: 0, null: false
    t.datetime "last_authenticated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key_handle"], name: "index_fido_usf_devices_on_key_handle"
    t.index ["last_authenticated_at"], name: "index_fido_usf_devices_on_last_authenticated_at"
    t.index ["user_type", "user_id"], name: "index_fido_usf_devices_on_user"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "group_permissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "group_id"
    t.uuid "permission_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_group_permissions_on_group_id"
    t.index ["permission_id"], name: "index_group_permissions_on_permission_id"
  end

  create_table "groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "parent_id"
    t.text "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "welcome_email"
    t.boolean "requires_2fa", default: false
    t.text "description"
    t.boolean "admin", default: false
    t.boolean "manager", default: false
    t.boolean "operator", default: false
    t.index ["parent_id"], name: "index_groups_on_parent_id"
  end

  create_table "logins", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "service_provider_type"
    t.uuid "service_provider_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "auth_type", default: "New Login"
    t.index ["service_provider_type", "service_provider_id"], name: "index_logins_on_service_provider"
    t.index ["user_id"], name: "index_logins_on_user_id"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.uuid "resource_owner_id"
    t.uuid "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.uuid "resource_owner_id"
    t.uuid "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "internal", default: false
    t.text "display_url"
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "oauth_openid_requests", force: :cascade do |t|
    t.integer "access_grant_id", null: false
    t.string "nonce", null: false
  end

  create_table "permissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "saml_service_providers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "issuer_or_entity_id", null: false
    t.text "metadata_url", null: false
    t.text "fingerprint"
    t.string "response_hosts", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "display_url"
    t.text "name"
    t.index ["issuer_or_entity_id"], name: "index_saml_service_providers_on_issuer_or_entity_id", unique: true
  end

  create_table "settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["var"], name: "index_settings_on_var", unique: true
  end

  create_table "user_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_user_groups_on_group_id"
    t.index ["user_id"], name: "index_user_groups_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.text "username"
    t.text "name"
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login"
    t.string "otp_backup_codes", array: true
    t.datetime "expires_at"
    t.datetime "last_activity_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "web_hook_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "web_hook_id", null: false
    t.text "trigger"
    t.text "url"
    t.text "request_data"
    t.text "response_headers"
    t.text "response_data"
    t.text "response_status"
    t.decimal "execution_duration"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["web_hook_id"], name: "index_web_hook_logs_on_web_hook_id"
  end

  create_table "web_hooks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.json "headers"
    t.json "template"
    t.text "encrypted_url"
    t.text "encrypted_url_iv"
    t.text "encrypted_token"
    t.text "encrypted_token_iv"
    t.boolean "enable_ssl_verification", default: true
    t.integer "recent_failures", limit: 2, default: 0
    t.integer "backoff_count", limit: 2, default: 0
    t.datetime "disabled_until"
    t.boolean "user_create_events", default: false
    t.boolean "user_update_events", default: false
    t.boolean "user_destroy_events", default: false
    t.boolean "group_create_events", default: false
    t.boolean "group_update_events", default: false
    t.boolean "group_destroy_events", default: false
    t.boolean "group_membership_create_events", default: false
    t.boolean "group_membership_destroy_events", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "custom_groupdata", "custom_group_data_types"
  add_foreign_key "custom_groupdata", "groups"
  add_foreign_key "custom_userdata", "custom_userdata_types"
  add_foreign_key "custom_userdata", "users"
  add_foreign_key "group_permissions", "groups"
  add_foreign_key "group_permissions", "permissions"
  add_foreign_key "logins", "users"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "oauth_openid_requests", "oauth_access_grants", column: "access_grant_id", on_delete: :cascade
  add_foreign_key "user_groups", "groups"
  add_foreign_key "user_groups", "users"
  add_foreign_key "web_hook_logs", "web_hooks"
end
