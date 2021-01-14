# frozen_string_literal: true

class Admin::CustomGroupDataTypesController < AdminController
  private

  def model
    CustomGroupDataType
  end

  def model_params
    params.require(:custom_group_data_type).permit(
      :name, :custom_type
    )
  end

  def whitelist_attributes
    %w[name custom_type]
  end
end
