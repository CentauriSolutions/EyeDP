class AddOrderToServiceProviders < ActiveRecord::Migration[6.1]
  def change
    add_column :saml_service_providers, :order, :integer, default: 0, null: false
    add_column :oauth_applications, :order, :integer, default: 0, null: false
  end
end
