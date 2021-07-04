# frozen_string_literal: true

class Admin::WebHooksController < AdminController
  private

  # def model_attributes
  #   %w[name description]
  # end

  def new_fields
    f = %w[headers template disabled_until]
    %w[user group].each do |rel|
      f << "#{rel}_created_events"
      f << "#{rel}_updated_events"
      f << "#{rel}_deleted_events"
    end
    f << 'group_membership_created_events'
    f << 'group_membership_deleted_events'
    f
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

  def includes
    [:web_hook_logs]
  end

  def model
    WebHook
  end

  def model_params
    params.require(:web_hook).permit!
  end

  def ensure_user_is_authorized!
    raise(ActionController::RoutingError, 'Not Found') \
      unless current_user&.admin? || current_user&.operator?
  end

  def help_text(name)
    case name
    when 'headers'
      'This should be valid JSON in key:value pairs. ' \
      "Headers will be set in the form of 'key=value'. " \
      'Liquid templating can be used to interpolate data into the template. ' \
      ''
    when 'template'
      'This should be valid JSON. Liquid templating can be used to interpolate data into the template.'
    end
  end
end
