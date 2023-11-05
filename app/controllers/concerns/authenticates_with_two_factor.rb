# frozen_string_literal: true

# == AuthenticatesWithTwoFactor
#
# Controller concern to handle two-factor authentication
module AuthenticatesWithTwoFactor # rubocop:disable Metrics/ModuleLength
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
    session[:otp_started] = Time.now.utc
    setup_u2f_authentication(user)
    setup_webauthn_authentication(user)

    render 'devise/sessions/two_factor'
  end

  def authenticate_with_two_factor # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
    user = self.resource = find_user
    return handle_changed_user(user) if user_password_changed?(user)

    return handle_expired_attempt if attempt_expired?

    if user_params[:otp_attempt].present? && session[:otp_user_id]
      authenticate_with_two_factor_via_otp(user)
    elsif user_params[:device_response].present? && session[:otp_user_id]
      authenticate_with_two_factor_via_u2f(user)
    elsif session[:authentication_challenge] && session[:otp_user_id]
      authenticate_with_two_factor_via_webauthn(user)
    elsif user&.valid_password?(user_params[:password])
      reset_session
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

  def setup_webauthn_authentication(user)
    return unless user.credentials.any?

    @options = WebAuthn::Credential.options_for_get(allow: user.credentials.map(&:external_id))

    # Store the newly generated challenge somewhere so you can have it
    # for the verification phase.
    session[:authentication_challenge] = @options.challenge
  end

  def authenticate_with_two_factor_via_webauthn(user) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    # Assuming you're using @github/webauthn-json package to send the `PublicKeyCredential` object back
    # in params[:publicKeyCredential]:
    # binding.pry
    webauthn_credential, stored_credential = relying_party.verify_authentication(
      webauthn_params,
      session[:authentication_challenge]
    ) do |webauthn_credential|
      # the returned object needs to respond to #public_key and #sign_count
      user.credentials.find_by(external_id: Base64.strict_encode64(webauthn_credential.raw_id))
    end

    # Update the stored credential sign count with the value from `webauthn_credential.sign_count`
    stored_credential.update!(
      sign_count: webauthn_credential.sign_count,
      last_authenticated_at: Time.zone.now
    )

    # Continue with successful sign in or 2FA verification...
    params[:format] = 'html'
    handle_two_factor_success(user)
  rescue WebAuthn::SignCountVerificationError, WebAuthn::Error
    # Cryptographic verification of the authenticator data succeeded, but the signature counter was less then or equal
    # to the stored value. This can have several reasons and depending on your risk tolerance you can choose to fail or
    # pass authentication. For more information see https://www.w3.org/TR/webauthn/#sign-counter
    handle_two_factor_failure(user, 'WebAuthn')
  end

  def handle_two_factor_failure(user, method)
    # user.increment_failed_attempts!
    Rails.logger.warn("Failed Login: user=#{user.username} ip=#{request.remote_ip} method=#{method}")
    flash.now[:alert] = format(_('Authentication via %{method} device failed.'), method:) # rubocop:disable Style/FormatStringToken
    prompt_for_two_factor(user)
  end

  def handle_two_factor_success(user)
    # Remove any lingering user data from login
    clear_two_factor_attempt!

    # remember_me(user) if user_params[:remember_me] == '1'
    sign_in(user, message: :two_factor_authenticated, event: :authentication)
  end

  def clear_two_factor_attempt!(purge: true)
    session.delete(:otp_user_id)
    session.delete(:user_password_hash)
    session.delete(:challenge)
    reset_session if purge
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

  def handle_expired_attempt
    clear_two_factor_attempt!

    redirect_to new_user_session_path,
                alert: _('It took too long to verify your authentication device. Please try again')
  end

  def attempt_expired?
    return false if session[:otp_started].nil?

    started = Time.zone.parse(session[:otp_started])

    started + 5.minutes < Time.now.utc
  end

  def webauthn_params
    params2 = params
    params2.delete(:session)
    params2
      .permit(
        :type, :id, :rawId,
        { user: [:remember_me] },
        { response: %i[authenticatorData clientDataJSON signature userHandle] },
        { clientExtensionResults: {} }
      )
  end
end
