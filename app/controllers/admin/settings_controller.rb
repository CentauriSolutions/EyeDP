# frozen_string_literal: true

class Admin::SettingsController < AdminController
  skip_before_action :set_model
  # GET /admin/settings
  # GET /admin/settings.json
  def index; end

  def openid_connect; end

  def saml; end

  def branding; end

  def templates; end

  # PATCH/PUT /admin/settings/1
  # PATCH/PUT /admin/settings/1.json
  def update # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    opts = setting_params
    opts[:expire_after] = opts[:expire_after].to_i.days unless opts[:expire_after].nil?
    opts[:expire_after] = nil if opts[:expire_after].present? && opts[:expire_after] == 0.days
    opts[:devise_reset_password_within] = opts[:devise_reset_password_within].to_i.days \
      if opts[:devise_reset_password_within].present?
    opts[:session_timeout_in] = opts[:session_timeout_in].to_i.hours unless opts[:session_timeout_in].nil?
    opts[:session_timeout_in] = nil if opts[:session_timeout_in].present? && opts[:session_timeout_in] == 0.seconds
    opts.each do |setting, value|
      Setting.send("#{setting}=", value)
    end
    redirect_back fallback_location: admin_settings_url, notice: 'Settings were successfully updated.'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_setting
    @setting = Setting.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def setting_params # rubocop:disable Metrics/MethodLength
    params.fetch(:setting, {}).permit(
      :idp_base, :html_title_base,
      :devise_reset_password_within,
      :session_timeout_in,
      :saml_certificate, :saml_key,
      :oidc_signing_key,
      :registration_enabled, :permanent_email,
      :logo, :logo_height, :logo_width,
      :home_template, :registered_home_template,
      :expire_after, :welcome_from_email,
      :admin_reset_email_template, :admin_welcome_email_template,
      :admin_reset_email_template_plaintext, :admin_welcome_email_template_plaintext
    )
  end

  def ensure_user_is_authorized!
    raise(ActionController::RoutingError, 'Not Found') \
      unless current_user&.admin? || current_user&.operator?
  end
end
