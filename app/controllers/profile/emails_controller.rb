# frozen_string_literal: true

class Profile::EmailsController < ApplicationController
  before_action :authenticate_user!

  def index
    @email = Email.new(user: current_user)
    @emails = current_user.emails
  end

  def create # rubocop:disable Metrics/MethodLength
    @email = Email.new(email_params)
    respond_to do |format|
      if @email.save
        @email.send_confirmation_instructions
        format.html { redirect_to profile_emails_path, notice: 'Email was successfully created.' }
        format.json { render :index, status: :created, location: @email }
      else
        format.html { render :index }
        format.json { render json: @email.errors, status: :unprocessable_entity }
      end
    end
  end

  def resend_confirmation
    email = Email.find_by(id: params[:email_id], user_id: current_user.id)
    email.send_confirmation_instructions
    redirect_to profile_emails_path, notice: 'Confirmation email was sent.'
  end

  # DELETE /profile/emails/#{model}/1
  # DELETE /profile/emails/#{model}/1.json
  def destroy
    @email = Email.find(params[:id])
    redirect_to :back, notice: "You don't have permission to delete this email" if @email.user != current_user
    @email.destroy
    respond_to do |format|
      format.html { redirect_to profile_emails_path, notice: 'Email was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  protected

  def email_params
    p = params.require(:email).permit('address')
    p[:user_id] = current_user.id
    p
  end
end
