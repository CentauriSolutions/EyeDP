# frozen_string_literal: true

class Profile::ProfileController < ApplicationController
  before_action :authenticate_user!

  def index; end

  def update # rubocop:disable Metrics/MethodLength
    custom_userdata_params.each do |name, value|
      custom_type = CustomUserdataType.where(name: name).first
      custom_datum = CustomUserdatum.where(
        user_id: current_user.id,
        custom_userdata_type: custom_type
      ).first_or_initialize
      next if custom_datum.read_only

      begin
        custom_datum.value = value
        custom_datum.save
      rescue RuntimeError
        flash[:error] = 'Failed to update userdata, invalid value'
      end
    end
    redirect_to profile_additional_properties_path
  end

  protected

  def custom_userdata_params
    params.require(:custom_data).permit!
  end
end
