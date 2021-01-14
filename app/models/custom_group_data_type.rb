# frozen_string_literal: true

class CustomGroupDataType < ApplicationRecord
  has_many :custom_groupdata, dependent: :destroy
end
