class CreateSamlServiceProviders < ActiveRecord::Migration[5.2]
  def change
    create_table :saml_service_providers, id: :uuid do |t|
      t.text :issuer_or_entity_id, null: false
      t.text :metadata_url, null: false
      t.text :fingerprint
      t.string :response_hosts, array: true

      t.timestamps
    end

    add_index :saml_service_providers, :issuer_or_entity_id, unique: true
  end
end
