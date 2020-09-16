# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  def new
    if Setting.registration_enabled
      super
    else
      flash[:info] = 'Registrations are not open'
      redirect_to root_path
    end
  end

  def create
    if Setting.registration_enabled
      super
    else
      flash[:info] = 'Registrations are not open'
      redirect_to root_path
    end
  end
end
