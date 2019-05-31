# frozen_string_literal: true

class Admin::GroupsController < AdminController
  private

  def model_attributes
    %w[name parent]
  end

  def new_fields
    ['name']
  end

  def form_relations
    {
      parent: {
        type: :select,
        options: { prompt: 'No Parent' },
        finder: -> { Group.all.collect { |u| [u.name, u.id] } }
      }
    }
  end

  def includes
    [:parent]
  end

  def model
    Group
  end

  def model_params
    p = params.require(:group).permit(:name, :parent)
    p[:parent_id] = p.delete(:parent) if p[:parent]
    p
  end
end
