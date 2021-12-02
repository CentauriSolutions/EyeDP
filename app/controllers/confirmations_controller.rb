# frozen_string_literal: true

class ConfirmationsController < Devise::ConfirmationsController
  # POST /resource/confirmation
  def create
    self.resource = Email.send_confirmation_instructions(address: resource_params[:email])
    yield resource if block_given?

    if successfully_sent?(resource)
      set_flash_message(:notice, :send_paranoid_instructions)
      redirect_to new_session_path(resource_name)
    else
      respond_with(resource)
    end
  end
end
