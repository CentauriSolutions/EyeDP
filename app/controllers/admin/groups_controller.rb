# frozen_string_literal: true

class Admin::GroupsController < AdminController
  def email
    @group = Group.find(params[:group_id])
    render :email, layout: nil
  end

  private

  def model_attributes
    %w[name parent permissions]
  end

  def new_fields
    ['name']
  end

  # rubocop:disable Metrics/MethodLength
  def form_relations
    {
      parent: {
        type: :select,
        options: { prompt: 'No Parent' },
        finder: lambda {
                  helpers.options_from_collection_for_select(Group.all, :id, :name, @model.parent.try(:id))
                }
      },
    }
  end
  # rubocop:enable Metrics/MethodLength

  def includes
    %i[parent permissions]
  end

  def model
    Group
  end

  def model_params
    p = params.require(:group).permit(
      :name, :parent, :welcome_email, permission_ids: [])
    p[:permission_ids] ||= []
    p[:parent_id] = p.delete(:parent) if p[:parent]
    p
  end

  def sort_whitelist
    %w[created_at name]
  end
end
