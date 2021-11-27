# frozen_string_literal: true

class Admin::ApplicationsController < AdminController
  def index
    super
    session[:show_secret] = nil
  end

  def show
    @show_secret = session[:show_secret]
    session[:show_secret] = nil
    super
  end

  def edit
    @show_secret = session[:show_secret]
    session[:show_secret] = nil
    super
  end

  def create
    super
    session[:show_secret] = true
  end

  def renew_secret
    @model = Application.find(params[:application_id])
    @model.renew_secret
    session[:show_secret] = true
    @model.save
    respond_to do |format|
      format.html { redirect_to [:admin, @model], notice: 'Secret was successfully rotated' }
      format.json { render :show, status: :ok, location: [:admin, @model] }
    end
  end

  private

  def application_attributes
    %w[name display_url uid secret internal redirect_uri scopes order image_url confidential groups
       custom_userdata_types]
  end
  helper_method :application_attributes

  def model_attributes
    %w[name display_url internal scopes confidential groups custom_userdata_types]
  end

  def new_fields
    %w[name display_url internal redirect_uri scopes order image_url description confidential]
  end

  def model
    Application
  end

  def model_params
    p = params.require('application').permit(
      :name, :display_url, :internal, :scopes, :uid, :order,
      :redirect_uri, :confidential, :image_url, :description, group_ids: [],
      custom_userdata_type_ids: []
    )
    %i[group_ids custom_userdata_type_ids].each do |key|
      p[key]&.reject!(&:empty?)
      p[key] ||= []
    end
    p
  end

  def help_text(field_name)
    {
      'order' => 'What order should this application appear in on the user dashboard'
    }[field_name]
  end
  helper_method :help_text

  def ensure_user_is_authorized!
    raise(ActionController::RoutingError, 'Not Found') \
      unless current_user&.admin? || current_user&.operator?
  end
end
