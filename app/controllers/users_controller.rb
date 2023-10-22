# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!
  sudo

  def new_webauthn # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    current_user.update!(webauthn_id: WebAuthn.generate_user_id) unless current_user.webauthn_id
    respond_to do |f|
      f.json do
        options = WebAuthn::Credential.options_for_create(
          user: { id: current_user.webauthn_id, name: current_user.username },
          exclude: current_user.credentials.map(&:external_id)
        )

        # Store the newly generated challenge somewhere so you can have it
        # for the verification phase.
        session[:creation_challenge] = options.challenge
        render json: options
      end
      f.html
    end
  end

  def create_webauthn # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    webauthn_credential = relying_party.verify_registration(
      webauthn_params,
      session[:creation_challenge]
    )

    credential = current_user.credentials.find_or_initialize_by(
      external_id: Base64.strict_encode64(webauthn_credential.raw_id)
    )
    if credential.update(
      nickname: webauthn_params[:credential_nickname],
      public_key: webauthn_credential.public_key,
      sign_count: webauthn_credential.sign_count,
      last_authenticated_at: Time.zone.now
    )
      render json: { status: 'ok' }, status: :ok
    else
      render json: "Couldn't add your Security Key", status: :unprocessable_entity
    end
  rescue WebAuthn::Error => e
    render json: "Verification failed: #{e.message}", status: :unprocessable_entity
  ensure
    session.delete('current_registration')
  end

  def delete_webauthn
    Credential.where(user_id: current_user.id, id: params[:id]).delete_all
    redirect_to profile_authentication_devices_path
  end

  def new_2fa
    current_user.otp_secret = User.generate_otp_secret(32) unless current_user.two_factor_otp_enabled?
    current_user.save!
    @qr_code = build_qr_code
  end

  def create_2fa
    if current_user.validate_and_consume_otp!(params[:pin_code])
      # ActiveSession.destroy_all_but_current(current_user, session)
      current_user.otp_required_for_login = true
      @codes = current_user.generate_otp_backup_codes!
      # current_user.otp_backup_codes = @codes
      current_user.save!

      render 'create_2fa'
    else
      @error = _('Invalid pin code')
      @qr_code = build_qr_code

      render 'new_2fa'
    end
  end

  def codes
    @codes = current_user.generate_otp_backup_codes!
    # current_user.otp_backup_codes = @codes
    current_user.save!
  end

  def disable_2fa
    current_user.disable_two_factor! params[:otp_only]

    redirect_to authenticated_root_path,
                status: :found,
                notice: s_('Two-factor authentication has been disabled successfully!')
  end

  def build_qr_code
    uri = current_user.otp_provisioning_uri(current_user.username, issuer: issuer_host)
    qrcode = RQRCode::QRCode.new(uri)

    qrcode.as_svg(
      offset: 0,
      color: '000',
      shape_rendering: 'crispEdges',
      module_size: 3.5,
      standalone: true
    )
  end

  def issuer_host
    Setting.idp_base
  end

  protected

  def webauthn_params
    params
      .permit(
        :type, :id, :rawId, :credential_nickname,
        { user: [:id] },
        { response: [:clientDataJSON, :attestationObject, { transports: [] }] },
        { clientExtensionResults: {} }
      )
  end
end
