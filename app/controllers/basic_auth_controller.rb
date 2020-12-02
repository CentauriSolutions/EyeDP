# frozen_string_literal: true

class BasicAuthController < ApplicationController
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def create
    authenticate_or_request_with_http_basic do |username, password|
      resource = User.where(username: username).first
      sign_in :user, resource if resource&.valid_password?(password)
    end
    warden.custom_failure! if performed?
    if user_signed_in?
      permission_checks = [params[:permission_name], "#{params[:permission_name]}.#{params[:format]}"]
      groups = current_user.asserted_groups
      effective_permissions = groups
                              .map(&:effective_permissions)
                              .flatten
                              .uniq
                              .detect { |f| permission_checks.include? f.name }
      if effective_permissions
        head :ok
      else
        head 403
      end
    else
      head 401
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
end
