# frozen_string_literal: true

class Admin::UsersController < AdminController
  def show
    super
    @logins = @model.logins.includes(:service_provider).order(created_at: :desc).limit(50)
  end

  def create
    super
    @model.send_admin_welcome_email if @model.persisted?
  end

  def reset_password
    @model = User.find(params[:user_id])
    respond_to do |format|
      if @model.force_password_reset!
        format.html { redirect_to [:edit, :admin, @model], notice: 'Password reset was processed successfully' }
        format.json { render :show, status: :ok, location: [:admin, @model] }
      else
        format.html { redirect_to [:admin, @model, :edit], notice: 'There was a problem processing the password reset' }

        format.json { render json: @model.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_custom_attributes # rubocop:disable Metrics/MethodLength
    @model = User.find(params[:user_id])
    custom_userdata_params.each do |name, value|
      custom_type = CustomUserdataType.where(name: name).first
      custom_datum = CustomUserdatum.where(
        user_id: @model.id,
        custom_userdata_type: custom_type
      ).first_or_initialize
      begin
        custom_datum.value = value
        custom_datum.save
      rescue RuntimeError
        flash[:error] = 'Failed to update userdata, invalid value'
      end
    end
    redirect_to [:edit, :admin, @model]
  end

  private

  def can_destroy?
    false
  end

  def includes
    [:groups]
  end

  def show_whitelist_attributes
    %w[email name username two_factor_enabled? groups roles expires_at last_activity_at]
  end

  def whitelist_attributes
    %w[email username name two_factor_enabled? groups roles expired?]
  end

  def model
    User
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def model_params # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    p = params.require(:user).permit(
      :email, :username, :email, :name, :expires_at,
      :password, :last_activity_at, group_ids: []
    )
    p[:group_ids] ||= []
    # A Manager cannot add a user to an operator or admin group
    if current_user.manager?
      p[:group_ids] -= Group.where(admin: true).or(Group.where(operator: true)).pluck(:id)
      # A manager cannot remove admin from an admin user nor operator from an operator user
      p[:group_ids] += @model.groups.where(admin: true).or(Group.where(operator: true)).pluck(:id)
    end
    p.delete(:password) if p[:password] && p[:password].empty?
    p
  end

  def sort_whitelist
    %w[created_at username email]
  end

  def filter_whitelist
    %w[username email group]
  end

  def filter(rel) # rubocop:disable Metrics/AbcSize
    if filter_whitelist.include? params[:filter_by]
      if params[:filter_by] == 'group'
        rel.joins(:user_groups).where(user_groups: { group_id: params[:filter] })
      else
        users = User.arel_table
        rel.where(users[params[:filter_by]].matches("%#{params[:filter]}%"))
      end
    else
      rel
    end
  end

  def custom_userdata_params
    params.require(:custom_data).permit!
  end

  def ensure_user_is_authorized!
    raise(ActionController::RoutingError, 'Not Found') \
      unless current_user&.admin? || current_user&.manager?
  end
end
