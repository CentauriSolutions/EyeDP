# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true
  # before_action :authenticate_user!

  after_action :set_useragent_and_ip_in_session
  before_action :set_locale

  before_action :configure_permitted_parameters, if: :devise_controller?

  before_action :store_user_location!, if: :storable_location?
  # The callback which stores the current location must be added before you authenticate the user
  # as `authenticate_user!` (or whatever your resource is) will halt the filter chain and redirect
  # before the location can be stored.

  def set_locale
    I18n.locale = params.fetch(:locale, I18n.default_locale).to_sym
  end

  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end

  def after_sign_in_path_for(resource)
    redirect = can_redirect_to(params[:redirect_to])
    request.env['omniauth.origin'] || redirect || stored_location_for(resource) || root_url
  end

  def peek_enabled?
    super || current_user&.admin?
  end

  # U2F (universal 2nd factor) devices need a unique identifier for the application
  # to perform authentication.
  # https://developers.yubico.com/U2F/App_ID.html
  def u2f_app_id
    request.base_url
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: %i[login otp_attempt])
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[username email])
    if Setting.permanent_email
      devise_parameter_sanitizer.permit(:account_update, keys: %i[name])
    else
      devise_parameter_sanitizer.permit(:account_update, keys: %i[email name])
    end
  end

  private

  # Its important that the location is NOT stored if:
  # - The request method is not GET (non idempotent)
  # - The request is handled by a Devise controller such as Devise::SessionsController as that could cause an
  #    infinite redirect loop.
  # - The request is an Ajax request as this can lead to very unexpected behaviour.
  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  def store_user_location!
    # :user is the scope we are authenticating
    store_location_for(:user, request.fullpath)
  end

  def can_redirect_to(redirect_to) # rubocop:disable Metrics/MethodLength
    return unless redirect_to

    hostname = begin
      URI.parse(redirect_to).hostname
    rescue URI::InvalidURIError
      nil
    end
    return unless hostname

    apps = Application.arel_table
    return redirect_to if Application.where(apps[:redirect_uri].matches("https://#{hostname}%")).any? ||
                          SamlServiceProvider.where(
                            '? = ANY ("saml_service_providers"."response_hosts")', hostname
                          ).any?
  end

  def set_useragent_and_ip_in_session
    session['ip'] = request.remote_ip
    session['user-agent'] = request.user_agent
  end
end
