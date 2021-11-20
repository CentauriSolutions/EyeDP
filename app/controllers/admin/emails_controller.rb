# frozen_string_literal: true

class Admin::EmailsController < AdminController
  def confirm
    email = Email.find_by(id: params[:email_id], user_id: params[:user_id])
    respond_to do |format|
      if email.confirm
        format.html do
          redirect_to admin_user_path(email.user, anchor: 'emails'), notice: 'Email was successfully confirmed.'
        end
      else
        format.html { redirect_to [:admin, email.user], alert: 'Something went wrong confirming email.' }
      end
    end
  end

  private

  def ensure_user_is_authorized!
    raise(ActionController::RoutingError, 'Not Found') \
      unless current_user&.admin? || current_user&.manager?
  end
end
