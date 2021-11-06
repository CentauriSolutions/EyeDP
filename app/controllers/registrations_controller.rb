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

  # PUT /resource
  # We need to use a copy of the resource because we don't want to change
  # the current user in place.
  def update # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)
    old_email = resource.email
    resource_updated = update_resource(resource, account_update_params)
    address = account_update_params.delete(:email)
    if address && (address != old_email)
      email = resource.emails.find_by(address: address)
      email.primary = true
      email.save
      email = resource.emails.find_by(address: old_email)
      email.primary = false
      email.save
    end
    yield resource if block_given?
    if resource_updated
      set_flash_message_for_update(resource, prev_unconfirmed_email)
      bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?

      respond_with resource, location: after_update_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      @resource = resource
      render 'profile/show'
    end
  end

  def update_needs_confirmation?(_resource, _previous)
    false
  end
end
