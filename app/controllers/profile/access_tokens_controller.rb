# frozen_string_literal: true

class Profile::AccessTokensController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_user_permission!

  def index
    @token = AccessToken.new(user: current_user)
    @tokens = current_user.access_tokens
    return unless session[:new_token]

    @new_token = AccessToken.find(session[:new_token])
    session.delete(:new_token)
  end

  def create # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    @token = AccessToken.new(token_params)
    respond_to do |format|
      if @token.save
        session[:new_token] = @token.id
        format.html { redirect_to profile_access_tokens_path, notice: 'Token was successfully created.' }
        format.json { render :index, status: :created, location: @token }
      else
        format.html { render :index }
        format.json { render json: @token.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /profile/access_tokens/#{model}/1
  # DELETE /profile/access_tokens/#{model}/1.json
  def destroy
    @token = AccessToken.find(params[:id])
    redirect_to :back, notice: "You don't have permission to delete this access token" if @token.user != current_user
    @token.destroy
    respond_to do |format|
      format.html { redirect_to profile_access_tokens_path, notice: 'Token was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  protected

  def token_params
    p = params.require(:access_token).permit(:name, :expires_at)
    p[:user_id] = current_user.id
    p
  end

  def verify_user_permission!
    raise(ActionController::RoutingError, 'Not Found') unless \
      current_user.groups.where(permit_token: true).any?
  end
end
