# frozen_string_literal: true

class Admin::SettingsController < AdminController
  skip_before_action :set_model
  # GET /admin/settings
  # GET /admin/settings.json
  def index; end

  # PATCH/PUT /admin/settings/1
  # PATCH/PUT /admin/settings/1.json
  def update # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    opts = setting_params
    opts[:registration_enabled] = if opts[:registration_enabled].nil?
                                    false
                                  else
                                    true
                                  end
    opts[:permemant_username] = if opts[:permemant_username].nil?
                                  false
                                else
                                  true
                                end
    opts[:expire_after] = if opts[:expire_after].present?
                            opts[:expire_after].to_i.days
                          # The below else is ignored because we need to
                          # ensure that opts[:expire_after] is nil rather
                          # than an empty string so that the expiration is
                          # disabled!
                          else # rubocop:disable Style/EmptyElse
                            nil
                          end
    opts.each do |setting, value|
      Setting.send("#{setting}=", value)
    end
    redirect_to admin_settings_url, notice: 'Settings were successfully updated.'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_setting
    @setting = Setting.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def setting_params
    params.fetch(:setting, {}).permit(
      :idp_base, :html_title_base,
      :saml_certificate, :saml_key,
      :oidc_signing_key,
      :registration_enabled, :permemant_username,
      :logo, :logo_height, :logo_width,
      :home_template, :registered_home_template,
      :expire_after, :welcome_from_email,
      :admin_reset_email_template, :admin_welcome_email_template
    )
  end
end
