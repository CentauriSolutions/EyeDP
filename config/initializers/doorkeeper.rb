# frozen_string_literal: true

Doorkeeper.configure do # rubocop:disable Metrics/BlockLength
  # Change the ORM that doorkeeper will use (needs plugins)
  orm :active_record

  base_controller 'ApplicationController'

  # Allow redirects to localhost
  force_ssl_in_redirect_uri { |uri| uri.host != 'localhost' || uri.host != '127.0.0.1' }

  # This block will be called to check whether the resource owner is authenticated or not.
  resource_owner_authenticator do
    app = Application.find_by(uid: request.query_parameters['client_id'])

    if user_signed_in?
      if app&.groups&.any?
        if (current_user.asserted_groups & app.groups).empty?
          redirect_to main_app.root_url, notice: 'You are not authorized to access this application.'
        else
          current_user
        end
      else
        current_user
      end
    else
      store_user_location! if storable_location?
      redirect_to(new_user_session_url)
      nil
    end
  end

  resource_owner_from_credentials do |_routes|
    user = User.find_for_database_authentication(login: params[:username])
    if user&.valid_for_authentication? { user.valid_password?(params[:password]) } && user&.active_for_authentication?
      request.env['warden'].set_user(user, scope: :user, store: false)
      user
    end
  end

  skip_authorization do |_resource_owner, client|
    client.application.internal?
  end

  # Define access token scopes for your provider
  # For more information go to
  # https://github.com/doorkeeper-gem/doorkeeper/wiki/Using-Scopes
  #
  default_scopes :openid
  optional_scopes :profile, :email, :address, :phone

  flows = %w[authorization_code implicit_oidc]
  flows << 'password' if ENV['ENABLE_PASSWORD_GRANT_FLOW']
  grant_flows flows
end
