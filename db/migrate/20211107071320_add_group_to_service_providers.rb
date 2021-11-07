class AddGroupToServiceProviders < ActiveRecord::Migration[6.1]
  def change
    create_table :group_service_providers, id: :uuid do |t|
      t.references :group, foreign_key: true, type: :uuid
      t.references :service_provider, polymorphic: true, type: :uuid

      t.timestamps
    end
  end
end
