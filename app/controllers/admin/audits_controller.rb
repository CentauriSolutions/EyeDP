# frozen_string_literal: true

class Admin::AuditsController < AdminController
  private

  def model
    Audited::Audit
  end

  def default_sort_dir
    :desc
  end

  def whitelist_attributes
    %w[auditable_type action audited_changes]
  end

  def hide_attribute?(attr_name)
    filtered_attrs = %w[encrypted_password reset_password_token]
    return false unless filtered_attrs.include? attr_name

    true
  end

  def redact(data)
    data.each do |key, _value|
      data[key] = '<REDACTED>' if hide_attribute?(key)
    end
    data
  end
  helper_method :redact

  def ensure_user_is_authorized!
    raise(ActionController::RoutingError, 'Not Found') \
      unless current_user&.admin?
  end
end
