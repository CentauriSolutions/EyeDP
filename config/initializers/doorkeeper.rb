# frozen_string_literal: true

Doorkeeper.configure do
  # Change the ORM that doorkeeper will use (needs plugins)
  orm :active_record

  base_controller 'ApplicationController'

  # This block will be called to check whether the resource owner is authenticated or not.
  resource_owner_authenticator do
    if current_user
      current_user
    else
      store_user_location! if storable_location?
      redirect_to(new_user_session_url)
      nil
    end
  end

  # Define access token scopes for your provider
  # For more information go to
  # https://github.com/doorkeeper-gem/doorkeeper/wiki/Using-Scopes
  #
  default_scopes :openid
  optional_scopes :profile, :email, :address, :phone

end
