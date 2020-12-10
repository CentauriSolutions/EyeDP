# frozen_string_literal: true

class CustomUserdataType < ApplicationRecord
  has_many :custom_userdata, dependent: :destroy
end
