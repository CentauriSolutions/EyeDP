# frozen_string_literal: true

class Admin::EmailsController < AdminController
  def create
    @model = User.find(params[:user_id])
    @email = Email.new(email_params)
    respond_to do |format|
      if @email.save
        format.html { redirect_to admin_user_path(@model), notice: 'Email was successfully created.' }
      else
        format.html { render :show }
      end
    end
  end

  def destroy
    model = User.find(params[:user_id])
    email = model.emails.find_by(id: params[:email_id])
    email.destroy
    redirect_to admin_user_path(model, anchor: 'emails'), notice: 'Email was successfully destroyed.'
  end

  def resend_confirmation
    model = User.find(params[:user_id])
    email = Email.find_by(id: params[:email_id], user_id: model.id)
    email.send_confirmation_instructions
    redirect_to admin_user_path(model, anchor: 'emails'), notice: 'Confirmation email was sent.'
  end

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

  def set_model; end

  def ensure_user_is_authorized!
    raise(ActionController::RoutingError, 'Not Found') \
      unless current_user&.admin? || current_user&.manager?
  end

  def email_params
    p = params.require(:email).permit('address')
    p[:user_id] = @model.id
    p
  end
end
