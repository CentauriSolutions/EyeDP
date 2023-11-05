# frozen_string_literal: true

class Api::UsersController < ApiController # rubocop:disable Metrics/ClassLength
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
      result: allow_list(User.find(params[:id]))
    }
  end

  def update # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    error('missing permission') and return unless @api_key.write_user?

    user = User.find(params[:id])
    old_email = user.email
    if user.update(user_params)
      address = user_params.delete(:email)
      if address && (address != old_email)
        email = user.emails.find_by(address:)
        email.primary = true
        email.save
        email = user.emails.find_by(address: old_email)
        email.primary = false
        email.save
      end
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

  def user_data # rubocop:disable Metrics/MethodLength
    # in the GET case, user_data_params should be an array of attributes
    # to read
    error('missing permission') and return unless @api_key.read_custom_data? && \
                                                  @api_key.matching_custom_data(user_data_params)

    user = User.find(params[:user_id])
    render json: {
      status: 'ok',
      result: user
        .custom_userdata
        .joins(:custom_userdata_type)
        .where(custom_userdata_type: { name: user_data_params })
        .includes(:custom_userdata_type)
        .map { |data| { name: data.name, value: data.value } }
    }
  end

  def update_user_data # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    # in the PUT / POST case, user_data_params should be a hash of attributes
    # to set with their values
    error('missing permission') and return unless @api_key.write_custom_data? && \
                                                  @api_key.matching_custom_data(user_data_params.keys)

    user = User.find(params[:user_id])
    results = {}
    error_messages = []
    ActiveRecord::Base.transaction do
      user_data_params.each do |name, value|
        custom_type = CustomUserdataType.where(name:).first
        custom_datum = CustomUserdatum.where(
          user_id: user.id,
          custom_userdata_type: custom_type
        ).first_or_initialize
        begin
          custom_datum.value = value
          custom_datum.save
          results[custom_datum.name] = custom_datum.value
        rescue RuntimeError
          error_messages << "#{custom_datum.name} has a bad value: #{value}"
        end
        raise ActiveRecord::Rollback if error_messages.any?
      end
    end
    if error_messages.any?
      render json: {
        status: 'error',
        error_messages:
      }, status: :unprocessable_entity
    else
      render json: {
        status: 'ok',
        result: results
      }
    end
  end

  protected

  def user_params
    params.require(:user).permit(
      :username, :email, :name
    )
  end

  def user_data_params
    params.require(:attributes)
  end

  def allow_list(user) # rubocop:disable Metrics/MethodLength
    {
      id: user.id,
      email: user.email,
      name: user.name,
      username: user.username,
      created_at: user.created_at,
      updated_at: user.updated_at,
      expires_at: user.expires_at,
      last_activity_at: user.last_activity_at,
      disabled_at: user.disabled_at
    }
  end
end
