# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  include Devise::Controllers::Rememberable
  include AuthenticatesWithTwoFactor

  prepend_before_action :authenticate_with_two_factor,
    if: -> { action_name == 'create' && two_factor_enabled? }

  # replaced with :require_no_authentication_without_flash
  skip_before_action :require_no_authentication, only: [:new, :create]
  prepend_before_action :require_no_authentication_without_flash, only: [:new, :create]
  # protect_from_forgery is already prepended in ApplicationController but
  # authenticate_with_two_factor which signs in the user is prepended before
  # that here.
  # We need to make sure CSRF token is verified before authenticating the user
  # because Devise.clean_up_csrf_token_on_authentication is set to true by
  # default to avoid CSRF token fixation attacks. Authenticating the user first
  # would cause the CSRF token to be cleared and then
  # RequestForgeryProtection#verify_authenticity_token would fail because of
  # token mismatch.
  protect_from_forgery with: :exception, prepend: true, except: :destroy

  def create
    super do |resource|
      # User has successfully signed in, so clear any unused reset token
      if resource.reset_password_token.present?
        resource.update(reset_password_token: nil,
                        reset_password_sent_at: nil)
      end

      flash[:notice] = nil

      # log_audit_event(current_user, resource, with: authentication_method)
      # log_user_activity(current_user)
    end
  end

  def user_params
    params.require(:user).permit(:login, :password, :remember_me, :otp_attempt, :device_response)
  end

  def find_user
    @user ||= begin
      if session[:otp_user_id] && user_params[:login]
        User.by_id_and_login(session[:otp_user_id], user_params[:login]).first
      elsif session[:otp_user_id]
        User.find(session[:otp_user_id])
      elsif user_params[:login]
        User.find_for_database_authentication(login: user_params[:login])
      end
    end
  end

  def two_factor_enabled?
    find_user&.two_factor_enabled?
  end

  def valid_otp_attempt?(user)
    user.validate_and_consume_otp!(user_params[:otp_attempt].strip) ||
      user.invalidate_otp_backup_code!(user_params[:otp_attempt].strip)
  end

  def require_no_authentication_without_flash
    require_no_authentication

    if flash[:alert] == I18n.t('devise.failure.already_authenticated')
      flash[:alert] = nil
    end
  end

end
