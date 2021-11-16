# frozen_string_literal: true

class Admin::UsersController < AdminController # rubocop:disable Metrics/ClassLength
  def show
    @email = Email.new(user: @model)
    @reset_token = session[:reset_token]
    session[:reset_token] = nil
    super
    @logins = @model.logins.includes(:service_provider).order(created_at: :desc).limit(50)
  end

  def create # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity
    options = model_params
    emails = options.delete(:emails) || []
    @model = model.new(options)
    @model.primary_email_record.confirmed_at = Time.now.utc
    emails.each do |email|
      next if email.blank?

      @model.emails << Email.new(address: email, confirmed_at: Time.now.utc)
    end
    respond_to do |format|
      if @model.save
        format.html { redirect_to [:admin, @model], notice: "#{@model.class.name} was successfully created." }
        format.json { render :show, status: :created, location: [:admin, @model] }
      else
        format.html { render :new }
        format.json { render json: @model.errors, status: :unprocessable_entity }
      end
    end
    return unless @model.persisted?

    if params[:send_welcome_email]
      @model.send_admin_welcome_email
    else
      session[:reset_token] = @model.send(:set_reset_password_token)
    end
  end

  def update # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
    if (@model.admin? || @model.operator?) && !current_user.admin?
      redirect_to \
        [:admin, @model], \
        notice: "#{@model.class.name} was not updated because you lack admin privileges." \
        and return
    end

    update_custom_attributes if params[:custom_data]
    old_email = @model.email
    super
    address = model_params.delete(:email)
    return unless address && address != old_email

    email = @model.emails.find_by(address: address)
    email.primary = true
    email.save
    email = @model.emails.find_by(address: old_email)
    email.primary = false
    email.save
  end

  def emails # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    @model = User.find(params[:user_id])
    show
    @email = Email.new(email_params)
    respond_to do |format|
      if @email.save
        @email.send_confirmation_instructions
        format.html { redirect_to admin_user_path(@model), notice: 'Email was successfully created.' }
        format.json { render :index, status: :created, location: [:admin, @email] }
      else
        format.html { render :show }
        format.json { render json: @email.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy_email
    model = User.find(params[:user_id])
    email = model.emails.find_by(id: params[:id])
    email.destroy
    redirect_to admin_user_path(model), notice: 'Email was successfully destroyed.'
  end

  def resend_confirmation
    model = User.find(params[:user_id])
    email = Email.find_by(id: params[:email_id], user_id: model.id)
    email.send_confirmation_instructions
    redirect_to admin_user_path(model), notice: 'Confirmation email was sent.'
  end

  def resend_welcome_email
    @model = User.find(params[:user_id])
    respond_to do |format|
      if @model.send_admin_welcome_email
        format.html { redirect_to [:edit, :admin, @model], notice: 'Welcome email will be sent.' }
        format.json { render :show, status: :ok, location: [:admin, @model] }
      else
        format.html { redirect_to [:admin, @model, :edit], notice: 'There was a problem processing the request' }

        format.json { render json: @model.errors, status: :unprocessable_entity }
      end
    end
  end

  def disable_two_factor # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    @model = User.find(params[:user_id])
    if (@model.admin? || @model.operator?) && !current_user.admin?
      redirect_to \
        [:admin, @model], \
        notice: "#{@model.class.name} was not updated because you lack admin privileges." \
        and return
    end

    respond_to do |format|
      if @model.disable_two_factor!
        format.html do
          redirect_to [:edit, :admin, @model], notice: 'Two factor was disabled successfully'
        end
        format.json { render :show, status: :ok, location: [:admin, @model] }
      else
        format.html do
          redirect_to [:admin, @model, :edit], notice: "There was a problem disabling the user's two factor"
        end

        format.json { render json: @model.errors, status: :unprocessable_entity }
      end
    end
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
        flash[:error] << 'Failed to update userdata, invalid value'
      end
    end
  end

  private

  def includes
    %i[groups emails access_tokens]
  end

  def show_whitelist_attributes
    %w[primary_email name username two_factor_enabled? groups roles expires_at last_activity_at]
  end

  def whitelist_attributes
    %w[email username name two_factor_enabled? groups roles expired?]
  end

  def model
    User
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def model_params # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
    allowlist_attrs = [
      :email, :username, :name, :expires_at,
      :password, :last_activity_at, { group_ids: [] }
    ]
    allowlist_attrs.push(emails: []) if params[:action] == 'create'
    p = params.require(:user).permit(
      allowlist_attrs
    )
    p[:group_ids] ||= []
    if current_user.manager? && !current_user.admin?
      # A Manager cannot add a user to an operator or admin group
      p[:group_ids] -= Group.where(admin: true).or(Group.where(operator: true)).pluck(:id)
      # A manager cannot remove admin from an admin user nor operator from an operator user
      p[:group_ids] += @model.groups.where(admin: true).or(Group.where(operator: true)).pluck(:id) unless @model.nil?
      p[:group_ids].uniq!
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

  def email_params
    p = params.require(:email).permit('address')
    p[:user_id] = @model.id
    p
  end

  def ensure_user_is_authorized!
    raise(ActionController::RoutingError, 'Not Found') \
      unless current_user&.admin? || current_user&.manager?
  end
end
