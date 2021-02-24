# frozen_string_literal: true

class Admin::PermissionsController < AdminController
  private

  def model_attributes
    %w[name description]
  end

  def new_fields
    %w[name description]
  end

  # def form_relations
  #   {
  #     parent: {
  #       type: :select,
  #       options: { prompt: 'No Parent' },
  #       finder: -> { Group.all.collect { |u| [u.name, u.id] } }
  #     }
  #   }
  # end

  # def includes
  #   [:parent]
  # end

  def model
    Permission
  end

  def model_params
    params.require(:permission).permit(:name, :description)
  end

  def ensure_user_is_authorized!
    raise(ActionController::RoutingError, 'Not Found') \
      unless current_user&.admin? || current_user&.operator?
  end
end
