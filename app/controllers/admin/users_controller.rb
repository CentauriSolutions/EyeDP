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
    emails = options.delete(:email_addresses) || []
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

  def update # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    if (@model.admin? || @model.operator?) && !current_user.admin?
      redirect_to \
        [:admin, @model], \
        notice: "#{@model.class.name} was not updated because you lack admin privileges." \
        and return
    end

    addresses = params[:user].delete(:email_addresses) || []
    update_custom_attributes if params[:custom_data]
    old_email = @model.email
    super
    address = model_params.delete(:email)
    all_addresses = addresses << address
    all_addresses.compact!
    @model.emails.where.not(address: all_addresses).destroy_all
    all_addresses.each do |email_address|
      Email.find_or_create_by(user: @model, address: email_address, confirmed_at: Time.zone.now)
    end
    return unless address && address != old_email

    email = @model.emails.find_by(address: address)
    email.primary = true
    email.save
    email = @model.emails.find_by(address: old_email)
    return if email.nil?

    email.primary = false
    email.save
  end

  def bulk_action # rubocop:disable Metrics/MethodLength
    finder = model.where(id: params[:ids])
    flash[:notice] = case params[:bulk_action]
                     when 'disable'
                       finder.update(disabled_at: Time.zone.now)
                       'Users were successfully disabled'
                     when 'enable'
                       finder.update(disabled_at: nil)
                       'Users were successfully enabled'
                     when 'reset_password'
                       finder.map(&:force_password_reset!)
                       'Password reset emails were successfully requested'
                     when 'resend_welcome_email'
                       finder.map(&:send_admin_welcome_email)
                       'Welcome emails will be sent.'
                     end
    render plain: ''
  end

  def resend_welcome_email
    @model = User.find(params[:user_id])
    respond_to do |format|
      if @model.send_admin_welcome_email
        format.html { redirect_to admin_user_path(@model, anchor: 'emails'), notice: 'Welcome email will be sent.' }
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
    %w[primary_email name username two_factor_enabled? disabled? groups roles expires_at last_activity_at]
  end

  def whitelist_attributes
    %w[email username name two_factor_enabled? groups roles expired? disabled?]
  end

  def model
    User
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def model_params # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    allowlist_attrs = [
      :email, :username, :name, :expires_at, :disabled_at,
      :password, :last_activity_at, :group_ids, { group_ids: [], email_addresses: [] }
    ]
    p = params.require(:user).permit(
      allowlist_attrs
    )
    if p[:group_ids] && current_user.manager? && !current_user.admin?
      # A Manager cannot add a user to an operator or admin group
      p[:group_ids] -= Group.where(admin: true).or(Group.where(operator: true)).pluck(:id)
      # A manager cannot remove admin from an admin user nor operator from an operator user
      p[:group_ids] += @model.groups.where(admin: true).or(Group.where(operator: true)).pluck(:id) unless @model.nil?
      p[:group_ids].uniq!
    end
    p.delete(:password) if p[:password] && p[:password].empty?
    p
  end

  def bulk_actions?
    true
  end
  helper_method :bulk_actions?

  def bulk_actions
    %i[disable enable reset_password resend_welcome_email]
  end
  helper_method :bulk_actions

  def sort_whitelist
    %w[created_at username name email]
  end

  def filter_whitelist
    %w[username email]
  end

  def filter(rel) # rubocop:disable Metrics/MethodLength
    return rel if params[:search].blank?

    clauses = []
    rel = rel.joins(:emails)
    filter_whitelist.each do |key|
      clauses << case key
                 # when 'group'
                 #   rel.or(model.where(groups[:name].matches("%#{params[:search]}%")))
                 when 'email'
                   'emails.address ilike :query'
                 else
                   "#{key} ilike :query"
                 end
    end
    rel.where(clauses.join(' or '), query: "%#{params[:search]}%")
  end

  def order(rel) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    sort = {
      sort_by: :created_at,
      sort_dir: default_sort_dir
    }
    sort[:sort_by] = params[:sort_by] if params[:sort_by] && sort_whitelist.include?(params[:sort_by])
    if sort[:sort_by] == 'email'
      rel = rel.joins(:emails).where(emails: { primary: true })
      sort[:sort_by] = 'address'
    end
    sort[:sort_dir] = params[:sort_dir] if params[:sort_dir] && %w[asc desc].include?(params[:sort_dir])
    rel.order({ sort[:sort_by] => sort[:sort_dir] })
  end

  def custom_userdata_params
    params.require(:custom_data).permit(CustomUserdataType.permit!)
  end

  def ensure_user_is_authorized!
    raise(ActionController::RoutingError, 'Not Found') \
      unless current_user&.admin? || current_user&.manager?
  end
end
