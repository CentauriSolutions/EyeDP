# frozen_string_literal: true

class UsersController < ApplicationController
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

    redirect_to edit_user_registration_path,
                status: :found,
                notice: s_('Two-factor authentication has been disabled successfully!')
  end

  def account_string
    "#{issuer_host}:#{current_user.email}"
  end

  def build_qr_code
    uri = current_user.otp_provisioning_uri(account_string, issuer: issuer_host)
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
end
