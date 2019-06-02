# frozen_string_literal: true

class BasicAuthController < ApplicationController
  def create
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
