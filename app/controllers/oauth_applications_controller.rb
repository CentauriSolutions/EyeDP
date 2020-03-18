# frozen_string_literal: true

class OauthApplicationsController < Doorkeeper::AuthorizationsController
  def create
    super
    Login.create(user: current_user, service_provider: Application.find_by(uid: params[:client_id]))
  end
end
