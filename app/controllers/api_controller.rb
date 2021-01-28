# frozen_string_literal: true

class ApiController < ApplicationController
  before_action :set_api_key
  skip_before_action :verify_authenticity_token

  protected

  def set_api_key # rubocop:disable Metrics/MethodLength
    api_key = request.headers['X-Api-Key'] || params[:api_key]
    unless api_key
      render json: {
        status: 'error',
        error: 'missing API key, please set X-Api-Key header or api_key GET parameter'
      }, status: :bad_request and return
    end

    @api_key = ApiKey.where(key: api_key).first
    return if @api_key

    render json: {
      status: 'error',
      error: 'invalid API key'
    }, status: :forbidden
  end

  def error(msg, code: :forbidden)
    render json: {
      status: 'error',
      error: msg
    }, status: code
  end
end
