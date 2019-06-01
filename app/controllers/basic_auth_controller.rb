# frozen_string_literal: true

class BasicAuthController < ApplicationController
  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :authenticate_user!, except: [:show]
  # rubocop:enable Rails/LexicallyScopedActionFilter

  # override create and make sure to set both "GET" and "POST" requests to /saml/auth to #create
  def create
    # binding.pry
    if user_signed_in?
      permission_checks = [params[:permission_name], "#{params[:permission_name]}.#{params[:format]}"]
      if current_user.permissions.where(name: permission_checks).any?
        head :ok
      else
        head :forbidden
      end
    else
      head :forbidden
    end
  end
end
