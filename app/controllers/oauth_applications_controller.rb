# frozen_string_literal: true

class OauthApplicationsController < Doorkeeper::AuthorizationsController
  def create
    super
    Login.create(user: current_user, service_provider: server.client.application)
  end
end
