# frozen_string_literal: true

class ProfileController < ApplicationController
  before_action :authenticate_user!
  before_action :check_group_2fa
  before_action :set_flash_on_restrictions

  def show # rubocop:disable Metrics/MethodLength
    @template = Liquid::Template.parse(Setting.registered_home_template) if Setting.registered_home_template.present?
    @logins = current_user
              .logins
              .includes([:service_provider])
              .select(
                'DISTINCT ON(logins.service_provider_id) logins.*'
              )
              .order(service_provider_id: :desc, created_at: :desc)
              .limit(10)
              .sort_by(&:created_at)
              .reverse
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

  protected

  def check_group_2fa
    @two_factor_required = []
    return if current_user.two_factor_enabled?

    groups = current_user.groups.where(requires_2fa: true)
    @two_factor_required = groups.pluck(:name) if groups.any?
  end

  def set_flash_on_restrictions
    @two_factor_required.each do |name|
      flash[name] = "You are a member of the group '#{name}' and it requires " \
                    "two factor. This group won't be accessible until you " \
                    'enable two-factor on your account'
    end
  end
end
