# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!

  def home
    # @template = Liquid::Template.parse(Setting.dashboard_template)
    @template = Liquid::Template.parse(File.read(Rails.root.join('templates/dashboard.liquid')))
    @applications = (saml_apps + openid_apps).sort_by(&:order)
  end

  def template_variables # rubocop:disable Metrics/MethodLength
    if current_user
      {
        'user' => {
          'username' => current_user.username,
          'email' => current_user.email
        },
        'groups' => current_user.groups.pluck(:name),
        'applications' => @applications.map do |app|
          {
            'name' => app.name,
            'url' => app.display_url,
            'image_url' => app.image_url.presence,
            'description' => app.description.presence
          }
        end
      }
    else
      {}
    end
  end
  helper_method :template_variables

  protected

  def saml_apps
    @saml_apps ||= SamlServiceProvider
                   .includes(:group_service_providers)
                   .where(group_service_providers: { id: nil })
                   .or(
                     SamlServiceProvider
                     .where(group_service_providers: { group: current_user.groups })
                   )
  end

  def openid_apps
    @openid_apps ||= Application
                     .includes(:group_service_providers)
                     .where(group_service_providers: { id: nil })
                     .or(
                       Application
                       .where(group_service_providers: { group: current_user.groups })
                     )
  end
end
