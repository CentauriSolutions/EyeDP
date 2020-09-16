# frozen_string_literal: true

class PagesController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: :home

  def home
    @template = Liquid::Template.parse(Setting.home_template)
  end

  def user_dashboard
    @template = Liquid::Template.parse(Setting.registered_home_template)
    @logins = current_user.logins.page(params[:page] || 1).includes(:service_provider).order(created_at: :desc)
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
