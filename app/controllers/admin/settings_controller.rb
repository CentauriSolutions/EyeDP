# frozen_string_literal: true

class Admin::SettingsController < AdminController
  skip_before_action :set_model
  # GET /admin/settings
  # GET /admin/settings.json
  def index; end

  # PATCH/PUT /admin/settings/1
  # PATCH/PUT /admin/settings/1.json
  def update
    opts = setting_params
    if opts[:registration_enabled].nil?
      opts[:registration_enabled] = false
    else
      opts[:registration_enabled] = true
    end
    if opts[:logo] != Setting.logo
      Rails.application.precompiled_assets.delete(Setting.logo)
    end
    opts.each do |setting, value|
      Setting.send("#{setting}=", value)
      puts "#{setting}: #{value}"
    end
    redirect_to admin_settings_url, notice: 'Settings were successfully updated.'
    # respond_to do |format|
    #   if @setting.update(setting_params)
    #     format.html { redirect_to @setting, notice: 'Setting was successfully updated.' }
    #     format.json { render :show, status: :ok, location: @setting }
    #   else
    #     format.html { render :edit }
    #     format.json { render json: @setting.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_setting
    @setting = Setting.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def setting_params
    params.fetch(:setting, {}).permit(
      :idp_base,
      :saml_certificate, :saml_key,
      :oidc_signing_key,
      :registration_enabled,
      :logo, :logo_height, :logo_width,
      :home_template, :registered_home_template,
    )
  end
end
