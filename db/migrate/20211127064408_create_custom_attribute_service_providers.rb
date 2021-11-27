class CreateCustomAttributeServiceProviders < ActiveRecord::Migration[6.1]
  def change
    create_table :custom_attribute_service_providers, id: :uuid do |t|
      t.references :application, null: false, type: :uuid, oreign_key: {to_table: 'Doorkeeper::Application'}
      t.references :custom_userdata_type, null: false, foreign_key: true, type: :uuid, index: { name: :index_custom_attribute_sp_on_custom_userdata_type }

      t.timestamps
    end
  end
end
