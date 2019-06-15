# frozen_string_literal: true

class PagesController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: :home

  def home; end

  def user_dashboard
    @logins = current_user.logins.page(params[:page] || 1).includes(:service_provider).order(created_at: :desc)
  end
end
