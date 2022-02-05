# frozen_string_literal: true

class BasicAuthController < ApplicationController
  skip_before_action :authorize_rack_mini_profiler

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def create
    key = request.headers['EyeDP-Authorize']
    token = AccessToken.where(token: key).where('expires_at > NOW() or expires_at IS NULL').first
    if token && token.user.asserted_groups.where(permit_token: true).any?
      @user = token.user
      token.update(last_used_at: Time.now.utc)
    end
    if @user.nil? && Setting.session_timeout_in.present?
      # We need to compare against the last request time here ourselves because
      # warden handles user timeout in a subtly different way to not logged in,
      # namely, not logged in causes the `user_signed_in` method to return
      # fakse, but timed out causes it to redirect to the login page.
      last_session_activity = session.try(:[], 'warden.user.user.session').try(:[], 'last_request_at')
      head :unauthorized and return if \
        last_session_activity.present? && \
        Time.at(last_session_activity).utc < Time.current - User.timeout_in.seconds
    end
    @user = current_user if user_signed_in? && @user.nil?
    if @user
      # we have to manually update the last_activity_at because we're
      # not letting warden do much
      session['warden.user.user.session']['last_request_at'] = Time.now.to_i \
        if current_user && Setting.session_timeout_in.present?
      permission_checks = [params[:permission_name], "#{params[:permission_name]}.#{params[:format]}"]
      groups = @user.asserted_groups
      effective_permissions = groups
                              .map(&:effective_permissions)
                              .flatten
                              .uniq
                              .detect { |f| permission_checks.include? f.name }
      if effective_permissions
        response.set_header('EyeDP-Username', @user.username)
        response.set_header('EyeDP-Email', @user.email)
        head :ok
      else
        head :forbidden
      end
    else
      head :unauthorized
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
end
