# frozen_string_literal: true

class Profile::EmailsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_model, only: %i[show edit update destroy]

  def index
    @email = Email.new(user: current_user)
    @emails = current_user.emails
  end

  def create
    @email = Email.new(email_params)
    respond_to do |format|
      if @email.save
        @email.send_confirmation_instructions
        format.html { redirect_to profile_emails_path, notice: "Email was successfully created." }
        format.json { render :index, status: :created, location: [:admin, @email] }
      else
        format.html { render :index }
        format.json { render json: @email.errors, status: :unprocessable_entity }
      end
    end
  end

  def resend_confirmation
    email = Email.where(id: params[:email_id], user_id: current_user.id)
    email.send_confirmation_instructions
    redirect_to profile_emails_path, notice: "Confirmation email was sent."
  end

  def update # rubocop:disable Metrics/MethodLength
    redirect_to profile_emails_path
  end

    # DELETE /profile/emails/#{model}/1
  # DELETE /profile/emails/#{model}/1.json
  def destroy
    redirect_to :back, notice: "You don't have permission to delete this email" if @email.user != current_user
    @email.destroy
    respond_to do |format|
      format.html { redirect_to profile_emails_path, notice: "Email was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  protected

  def set_model
    @email = Email.find(params[:id])
  end

  def email_params
    p = params.require(:email).permit!
    p[:user_id] = current_user.id
    p
  end
end
