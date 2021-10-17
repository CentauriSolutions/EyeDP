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

  def ensure_user_is_authorized!
    raise(ActionController::RoutingError, 'Not Found') \
      unless current_user&.admin?
  end
end
