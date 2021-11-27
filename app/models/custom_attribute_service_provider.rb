# frozen_string_literal: true

class CustomAttributeServiceProvider < ApplicationRecord
  belongs_to :application
  belongs_to :custom_userdata_type
  after_save :reload_doorkeeper

  def reload_doorkeeper
    load(Rails.root.join('config/initializers/doorkeeper_openid_connect.rb'))
  end
end
