# frozen_string_literal: true

class BasicAuthController < ApplicationController
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
        head :unauthorized
      end
    else
      head :unauthorized
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end
