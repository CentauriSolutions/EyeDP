# frozen_string_literal: true

class Profile::AccessGrantsController < ApplicationController
  before_action :authenticate_user!

  def index
    @tokens = tokens
    @grants = grants
  end

  def revoke # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    token = case params[:kind]
            when 'token'
              current_user.oauth_access_tokens.find(params[:id])
            when 'grant'
              current_user.oauth_access_grants.find(params[:id])
            end
    token.revoke
    respond_to do |format|
      format.html { redirect_to profile_access_grants_path, notice: 'Access was successfully revoked.' }
      format.json { head :no_content }
    end
  end

  def revoke_all
    current_user.oauth_access_tokens.update(revoked_at: Time.zone.now)
    current_user.oauth_access_grants.update(revoked_at: Time.zone.now)
    redirect_to profile_access_grants_path, notice: 'Access was successfully revoked.'
  end

  protected

  def tokens
    current_user.oauth_access_tokens
                .select('DISTINCT ON (application_id) *')
                .joins(:application)
                .includes(:application)
                .where(revoked_at: nil, application: { internal: false })
                .order(:application_id, created_at: :desc)
  end

  def grants
    current_user.oauth_access_grants
                .select('DISTINCT ON (application_id) *')
                .joins(:application)
                .includes(:application)
                .where(revoked_at: nil, application: { internal: false })
                .where.not(application: @tokens.map(&:application))
                .order(:application_id, created_at: :desc)
  end
end
