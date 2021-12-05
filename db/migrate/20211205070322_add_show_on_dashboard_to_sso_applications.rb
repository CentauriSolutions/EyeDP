class AddShowOnDashboardToSsoApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :oauth_applications, :show_on_dashboard, :boolean, default: true
    add_column :saml_service_providers, :show_on_dashboard, :boolean, default: true
  end
end
