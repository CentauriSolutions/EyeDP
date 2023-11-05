# frozen_string_literal: true

class Admin::GroupsController < AdminController
  def email
    @group = Group.find(params[:group_id])
    render :email, layout: nil
  end

  def update
    update_custom_attributes if params[:custom_data]
    super
  end

  def update_custom_attributes # rubocop:disable Metrics/MethodLength
    custom_groupdata_params.each do |name, value|
      custom_type = CustomGroupDataType.where(name:).first
      custom_datum = CustomGroupdatum.where(
        group_id: @model.id,
        custom_group_data_type: custom_type
      ).first_or_initialize
      begin
        custom_datum.value = value
        custom_datum.save
      rescue RuntimeError
        flash[:error] << 'Failed to update group data, invalid value'
      end
    end
  end

  private

  def whitelist_attributes
    %w[name parent requires_2fa permit_token roles permissions]
  end

  def new_fields
    %w[name description permit_token requires_2fa]
  end

  def show_whitelist_attributes
    %w[name description parent requires_2fa permit_token roles permissions]
  end

  def form_relations
    {
      parent: {
        type: :select,
        options: { prompt: 'No Parent' },
        finder: lambda {
                  helpers.options_from_collection_for_select(Group.all, :id, :name, @model.parent.try(:id))
                }
      }
    }
  end

  def includes
    %i[parent permissions]
  end

  def model
    Group
  end

  def model_params # rubocop:disable Metrics/MethodLength
    permitted_params = [
      :name, :description, :parent, :welcome_email, :requires_2fa,
      :permit_token, { permission_ids: [] }
    ]
    if current_user.admin?
      permitted_params << :admin
      permitted_params << :operator
      permitted_params << :manager
    end
    permitted_params << :manager if current_user.manager?
    p = params.require(:group).permit(permitted_params)

    p[:permission_ids] ||= []
    p[:parent_id] = p.delete(:parent) if p[:parent]
    p
  end

  def sort_whitelist
    %w[created_at name]
  end

  def custom_groupdata_params
    params.require(:custom_data).permit(CustomGroupDataType.permit!)
  end

  def ensure_user_is_authorized!
    raise(ActionController::RoutingError, 'Not Found') \
      unless current_user&.admin? || current_user&.manager?
  end
end
