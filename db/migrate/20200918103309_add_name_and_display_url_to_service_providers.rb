class AddNameAndDisplayUrlToServiceProviders < ActiveRecord::Migration[6.0]
  def change
    add_column :oauth_applications, :display_url, :text
    add_column :saml_service_providers, :display_url, :text
    add_column :saml_service_providers, :name, :text
  end
end
