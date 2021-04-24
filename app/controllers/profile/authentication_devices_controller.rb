# frozen_string_literal: true

class Profile::AuthenticationDevicesController < ApplicationController
  before_action :authenticate_user!
  def index; end
end
