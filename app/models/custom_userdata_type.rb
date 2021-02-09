# frozen_string_literal: true

class CustomUserdataType < ApplicationRecord
  audited

  has_many :custom_userdata, dependent: :destroy
end
