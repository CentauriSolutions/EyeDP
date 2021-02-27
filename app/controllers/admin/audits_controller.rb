# frozen_string_literal: true

class Admin::AuditsController < AdminController
  private

  def model
    Audited::Audit
  end

  def whitelist_attributes
    %w[auditable_type audited_changes]
  end

  def ensure_user_is_authorized!
    raise(ActionController::RoutingError, 'Not Found') \
      unless current_user&.admin?
  end
end
