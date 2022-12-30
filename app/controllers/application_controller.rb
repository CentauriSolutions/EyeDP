# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true
  # before_action :authenticate_user!

  after_action :set_useragent_and_ip_in_session
  before_action :set_locale
  before_action :authorize_rack_mini_profiler

  before_action :configure_permitted_parameters, if: :devise_controller?

  before_action :store_user_location!, if: :storable_location?

  before_action :set_flash_on_restrictions, if: -> { current_user }

  # The callback which stores the current location must be added before you authenticate the user
  # as `authenticate_user!` (or whatever your resource is) will halt the filter chain and redirect
  # before the location can be stored.

  def set_locale
    I18n.locale = (params.fetch(:locale, session[:locale]) || I18n.default_locale).to_sym
    session[:locale] = I18n.locale
  end

  def after_sign_in_path_for(resource)
    redirect = can_redirect_to(params[:redirect_to])
    request.env['omniauth.origin'] || redirect || stored_location_for(resource) || root_url
  end

  def authorize_rack_mini_profiler
    Rack::MiniProfiler.authorize_request if current_user&.admin? && Setting.profiler_enabled
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

  def check_group_2fa
    @two_factor_required = []
    return if current_user.two_factor_enabled?

    groups = current_user.groups.where(requires_2fa: true)
    @two_factor_required = groups.pluck(:name) if groups.any?
  end

  def set_flash_on_restrictions
    check_group_2fa
    @two_factor_required.each do |name|
      flash[name] = "You are a member of the group '#{name}' and it requires " \
                    "two factor. This group won't be accessible until you " \
                    'enable two-factor on your account'
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

    redirect_to = URI.parse(redirect_to)
    hostname = begin
      redirect_to.hostname
    rescue URI::InvalidURIError
      nil
    end
    return unless hostname

    oidc_app = oidc_app_redirect(redirect_to)
    return oidc_app if oidc_app

    saml_app_redirect(redirect_to)
  end

  def set_useragent_and_ip_in_session
    session['ip'] = request.remote_ip
    session['user-agent'] = request.user_agent
  end

  def oidc_app_redirect(redirect_to)
    apps = Application.arel_table
    possible_matching_apps = Application.where(apps[:redirect_uri].matches("https://#{redirect_to.hostname}%"))
    possible_matching_apps.each do |app|
      uri = URI.parse(app.redirect_uri)
      return build_app_redirect_uri_from(redirect_to, app, uri) if uri.hostname == redirect_to.hostname
    end
    nil
  end

  def saml_app_redirect(redirect_to)
    possible_matching_apps = SamlServiceProvider.where(
      '? = ANY ("saml_service_providers"."response_hosts")', redirect_to.hostname
    )
    possible_matching_apps.each do |app|
      app.response_hosts.each do |host|
        uri = URI.parse("https://#{host}")
        return build_app_redirect_uri_from(redirect_to, app, uri) if uri.hostname == redirect_to.hostname
      end
    end
    nil
  end

  def build_app_redirect_uri_from(redirect_to, app, app_uri)
    uri = URI.parse('')
    uri.scheme = app_uri.scheme || 'https'
    uri.hostname = redirect_to.hostname

    uri.path = redirect_to.path if app.allow_path_in_redirects
    uri.to_s
  end
end
