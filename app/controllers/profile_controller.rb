# frozen_string_literal: true

class ProfileController < ApplicationController
  def show
    @template = Liquid::Template.parse(Setting.registered_home_template)
    @logins = current_user
              .logins
              .select(
                'DISTINCT ON(logins.service_provider_id) logins.*'
              )
              .order(service_provider_id: :desc, created_at: :desc)
              .limit(10)
  end

  def template_variables # rubocop:disable Metrics/MethodLength
    if current_user
      {
        'user' => {
          'username' => current_user.username,
          'email' => current_user.email
        },
        'groups' => current_user.groups.pluck(:name)
      }
    else
      {}
    end
  end
  helper_method :template_variables
end
