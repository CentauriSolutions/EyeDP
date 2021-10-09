# frozen_string_literal: true

class OauthApplicationsController < Doorkeeper::AuthorizationsController
  sudo if: -> { Setting.sudo_for_sso }

  def new
    super
    Login.create(
      user: current_user,
      auth_type: 'Existing Login',
      service_provider: Application.find_by(uid: params[:client_id])
    )
  end

  def create
    super
    Login.create(
      user: current_user,
      service_provider: Application.find_by(uid: params[:client_id])
    )
  end
end
