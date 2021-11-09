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
    %w[name display_url uid secret internal redirect_uri scopes confidential groups]
  end
  helper_method :application_attributes

  def model_attributes
    %w[name display_url uid internal redirect_uri scopes confidential groups]
  end

  def new_fields
    %w[name display_url internal redirect_uri scopes confidential]
  end

  def model
    Application
  end

  def model_params
    p = params.require('application').permit(
      :name, :display_url, :internal, :scopes, :uid,
      :redirect_uri, :confidential, group_ids: []
    )
    p[:group_ids]&.reject!(&:empty?)
    p[:group_ids] ||= []
    p
  end

  def ensure_user_is_authorized!
    raise(ActionController::RoutingError, 'Not Found') \
      unless current_user&.admin? || current_user&.operator?
  end
end
