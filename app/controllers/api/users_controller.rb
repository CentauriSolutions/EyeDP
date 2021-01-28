# frozen_string_literal: true

class Api::UsersController < ApiController
  def index
    error('missing permission') and return unless @api_key.list_users?

    render json: {
      status: 'ok',
      result: User.all.map { |u| { id: u.id, username: u.username, email: u.email } }
    }
  end

  def show
    error('missing permission') and return unless @api_key.read_user?

    render json: {
      status: 'ok',
      result: User.find(params[:id])
    }
  end

  def update # rubocop:disable Metrics/MethodLength
    error('missing permission') and return unless @api_key.write_user?

    user = User.find(params[:id])
    if user.update(user_params)
      render json: {
        status: 'ok',
        result: user
      }
    else
      render json: {
        status: 'error',
        errors: user.errors
      }, status: :bad_request
    end
  end

  protected

  def user_params
    params.require(:user).permit(
      :username, :email, :name
    )
  end
end
