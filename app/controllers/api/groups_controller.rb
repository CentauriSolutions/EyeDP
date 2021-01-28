# frozen_string_literal: true

class Api::GroupsController < ApiController
  def index
    error('missing permission') and return unless @api_key.list_groups?

    render json: {
      status: 'ok',
      result: Group.all.map { |g| { id: g.id, name: g.name } }
    }
  end

  def show
    error('missing permission') and return unless @api_key.read_group?

    render json: {
      status: 'ok',
      result: Group.find(params[:id])
    }
  end

  def update # rubocop:disable Metrics/MethodLength
    error('missing permission') and return unless @api_key.write_group?

    group = Group.find(params[:id])
    if group.update(group_params)
      render json: {
        status: 'ok',
        result: group
      }
    else
      render json: {
        status: 'error',
        errors: group.errors
      }, status: :bad_request
    end
  end

  def list_users
    error('missing permission') and return unless @api_key.read_group_members?

    render json: {
      status: 'ok',
      result: Group.find(params[:group_id])
                   .users.map { |u| { id: u.id, username: u.username, email: u.email } }
    }
  end

  def add_user
    error('missing permission') and return unless @api_key.write_group_members?

    UserGroup.where(user_id: params[:user_id], group_id: params[:group_id]).first_or_create!
    render json: {
      status: 'ok'
    }
  end

  def remove_user
    error('missing permission') and return unless @api_key.write_group_members?

    user_group = UserGroup.where(user_id: params[:user_id], group_id: params[:group_id]).first
    user_group&.destroy
    render json: {
      status: 'ok'
    }
  end

  def group_params
    opts = %i[name description welcome_email parent_id welcome_email
              requires_2fa]
    opts.append(:admin) if @api_key.control_admin_groups?
    params.require(:group).permit(opts)
  end
end
