class AddAllowPathInRedirectsToSsoApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :oauth_applications, :allow_path_in_redirects, :bool, default: false
    add_column :saml_service_providers, :allow_path_in_redirects, :bool, default: false
  end
end
