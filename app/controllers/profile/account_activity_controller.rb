# frozen_string_literal: true

class Profile::AccountActivityController < ApplicationController
  before_action :authenticate_user!
  def index
    @logins = current_user.logins.includes(:service_provider).order(created_at: :desc).limit(50)
  end
end
