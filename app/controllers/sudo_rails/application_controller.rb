# frozen_string_literal: true

module SudoRails
  class ApplicationController < ActionController::Base
    before_action :sudo_enabled?

    def confirm # rubocop:disable Metrics/AbcSize
      if valid_otp_attempt?(current_user) || \
         valid_u2f_attempt?(current_user) || \
         SudoRails.confirm?(self, params[:password])
        session[:sudo_session] = Time.zone.now.to_s
      else
        flash[:alert] = I18n.t('sudo_rails.invalid_pass', locale: params[:locale])
      end
      redirect_to params[:target_path] if can_redirect_to(params[:target_path])
    end

    # U2F (universal 2nd factor) devices need a unique identifier for the application
    # to perform authentication.
    # https://developers.yubico.com/U2F/App_ID.html
    def u2f_app_id
      request.base_url
    end

    private

    def can_redirect_to(redirect_to)
      return unless redirect_to

      hostname = begin
        URI.parse(redirect_to).hostname
      rescue URI::InvalidURIError
        nil
      end
      hostname.nil? || hostname == request.hostname
    end

    def valid_otp_attempt?(user)
      user_params[:otp_attempt] && \
        (user.validate_and_consume_otp!(user_params[:otp_attempt].strip) ||
          user.invalidate_otp_backup_code!(user_params[:otp_attempt].strip))
    end

    def valid_u2f_attempt?(user)
      user_params[:device_response] && \
        User.u2f_authenticate(user, u2f_app_id, user_params[:device_response], session[:challenge])
    end

    def user_params
      params.require(:user).permit(:otp_attempt, :device_response)
    rescue ActionController::ParameterMissing
      {}
    end

    def sudo_enabled?
      SudoRails.enabled || head(:not_found, message: 'SudoRails disabled')
    end
  end
end
