# frozen_string_literal: true

class Admin::AuditsController < AdminController
  private

  def model
    Audited::Audit
  end

  def whitelist_attributes
    %w[auditable_type audited_changes]
  end
end
