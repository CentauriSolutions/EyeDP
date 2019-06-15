# frozen_string_literal: true

class BasicAuthController < ApplicationController
  before_action :authenticate_user!

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def create
    if user_signed_in?
      permission_checks = [params[:permission_name], "#{params[:permission_name]}.#{params[:format]}"]
      groups = current_user.groups
      effective_permissions = groups
                              .map(&:effective_permissions)
                              .flatten
                              .uniq
                              .detect { |f| permission_checks.include? f.name }
      if effective_permissions
        head :ok
      else
        head :forbidden
      end
    else
      head :forbidden
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end
