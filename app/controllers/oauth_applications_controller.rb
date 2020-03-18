# frozen_string_literal: true

class OauthApplicationsController < Doorkeeper::AuthorizationsController
  def create
    super
    Login.create(user: current_user, service_provider: server.client_via_uid.application)
  end
end
