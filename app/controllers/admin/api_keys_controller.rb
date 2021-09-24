# frozen_string_literal: true

class Admin::ApiKeysController < AdminController
  private

  def model
    ApiKey
  end

  def model_attributes
    %w[name description capabilities]
  end

  def new_fields
    %w[name description]
  end

  def ensure_user_is_authorized!
    raise(ActionController::RoutingError, 'Not Found') \
      unless current_user&.admin?
  end

  def model_params
    p = params.require('api_key').permit(
      :name, :description, :custom_data
    )
    p[:capabilities_mask] = params[:capabilities].values.map(&:to_i).sum \
      if params[:capabilities]
    p[:custom_data] = p[:custom_data].split(';') if p[:custom_data]
    p
  end
end
