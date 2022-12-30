# frozen_string_literal: true

class Admin::WebHooksController < AdminController
  private

  def model_attributes
    f = %w[headers template url token disabled_until]
    %w[user group].each do |rel|
      f << "#{rel}_create_events"
      f << "#{rel}_update_events"
      f << "#{rel}_destroy_events"
    end
    f << 'group_membership_create_events'
    f << 'group_membership_destroy_events'
    f
  end

  def new_fields
    model_attributes
  end

  def includes
    [:web_hook_logs]
  end

  def model
    WebHook
  end

  def model_params
    p = params.require(:web_hook).permit(model_attributes)
    p[:template] = nil if p[:template].empty?
    p[:headers] = nil if p[:headers].empty?
    p
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
