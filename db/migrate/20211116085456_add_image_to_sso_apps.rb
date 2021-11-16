class AddImageToSsoApps < ActiveRecord::Migration[6.1]
  def change
    add_column :saml_service_providers, :image_url, :text
    add_column :oauth_applications, :image_url, :text

    add_column :saml_service_providers, :description, :text
    add_column :oauth_applications, :description, :text
  end
end
