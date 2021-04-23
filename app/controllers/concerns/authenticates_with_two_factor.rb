# frozen_string_literal: true

# == AuthenticatesWithTwoFactor
#
# Controller concern to handle two-factor authentication
module AuthenticatesWithTwoFactor
  extend ActiveSupport::Concern

  # Store the user's ID in the session for later retrieval and render the
  # two factor code prompt
  #
  # The user must have been authenticated with a valid login and password
  # before calling this method!
  #
  # user - User record
  #
  # Returns nil
  def prompt_for_two_factor(user)
    # Set @user for Devise views
    @user = user

    session[:otp_user_id] = user.id
    session[:user_password_hash] = Digest::SHA256.hexdigest(user.encrypted_password)

    setup_u2f_authentication(user)

    render 'devise/sessions/two_factor'
  end

  def authenticate_with_two_factor # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    user = self.resource = find_user
    return handle_changed_user(user) if user_password_changed?(user)

    if user_params[:otp_attempt].present? && session[:otp_user_id]
      authenticate_with_two_factor_via_otp(user)
    elsif user_params[:device_response].present? && session[:otp_user_id]
      authenticate_with_two_factor_via_u2f(user)
    elsif user&.valid_password?(user_params[:password])
      prompt_for_two_factor(user)
    end
  end

  def authenticate_with_two_factor_via_otp(user)
    if valid_otp_attempt?(user)
      # Remove any lingering user data from login
      clear_two_factor_attempt!

      # remember_me(user) if user_params[:remember_me] == '1'
      user.save!
      sign_in(user, message: :two_factor_authenticated, event: :authentication)
    else
      # user.increment_failed_attempts!
      Rails.logger.warn("Failed Login: user=#{user.username} ip=#{request.remote_ip} method=OTP")
      flash.now[:alert] = _('Invalid two-factor code.')
      prompt_for_two_factor(user)
    end
  end

  # Setup in preparation of communication with a U2F (universal 2nd factor) device
  # Actual communication is performed using a Javascript API
  def setup_u2f_authentication(user)
    key_handles = user.fido_usf_devices.pluck(:key_handle)
    u2f = U2F::U2F.new(u2f_app_id)
    return if key_handles.blank?

    sign_requests = u2f.authentication_requests(key_handles)
    session[:challenge] ||= u2f.challenge
    @app_id = u2f_app_id
    @sign_requests = sign_requests
    @challenge = session[:challenge]
  end

  # Authenticate using the response from a U2F (universal 2nd factor) device
  def authenticate_with_two_factor_via_u2f(user)
    if User.u2f_authenticate(user, u2f_app_id, user_params[:device_response], session[:challenge])
      handle_two_factor_success(user)
    else
      handle_two_factor_failure(user, 'U2F')
    end
  end

  def handle_two_factor_failure(user, method)
    # user.increment_failed_attempts!
    Rails.logger.warn("Failed Login: user=#{user.username} ip=#{request.remote_ip} method=#{method}")
    flash.now[:alert] = format(_('Authentication via %{method} device failed.'), method: method) # rubocop:disable Style/FormatStringToken
    prompt_for_two_factor(user)
  end

  def handle_two_factor_success(user)
    # Remove any lingering user data from login
    clear_two_factor_attempt!

    # remember_me(user) if user_params[:remember_me] == '1'
    sign_in(user, message: :two_factor_authenticated, event: :authentication)
  end

  def clear_two_factor_attempt!
    session.delete(:otp_user_id)
    session.delete(:user_password_hash)
    session.delete(:challenge)
  end

  def handle_changed_user(_user)
    clear_two_factor_attempt!

    redirect_to new_user_session_path, alert: _('An error occurred. Please sign in again.')
  end

  # If user has been updated since we validated the password,
  # the password might have changed.
  def user_password_changed?(user)
    return false unless session[:user_password_hash]

    Digest::SHA256.hexdigest(user.encrypted_password) != session[:user_password_hash]
  end
end
