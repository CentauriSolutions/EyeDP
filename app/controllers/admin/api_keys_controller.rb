# frozen_string_literal: true

class Admin::ApiKeysController < AdminController
  private

  def model
    ApiKey
  end

  def model_attributes
    if action_name == 'index'
      %w[name description]
    else
      super
    end
  end

  # def new_fields
  #   %w[name description]
  # end

  def ensure_user_is_authorized!
    raise(ActionController::RoutingError, 'Not Found') \
      unless current_user&.admin?
  end

  def model_params
    params.require('api_key').permit(
      :name, :description, :custom_data, :list_groups, :read_group, :write_group,
      :list_users, :read_user, :write_user, :read_group_members, :write_group_members,
      :control_admin_groups, :read_custom_data, :write_custom_data
    )
  end
end
