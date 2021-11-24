# frozen_string_literal: true

class CustomGroupDataType < ApplicationRecord
  audited

  has_many :custom_groupdata, dependent: :destroy

  def self.permit!
    CustomGroupDataType.pluck(:name, :custom_type).map do |name, kind|
      if kind == 'array'
        { name.to_sym => [] }
      else
        name.to_sym
      end
    end
  end
end
