# frozen_string_literal: true

class CustomGroupDataType < ApplicationRecord
  audited

  has_many :custom_groupdata, dependent: :destroy
end
