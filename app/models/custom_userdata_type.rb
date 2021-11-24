# frozen_string_literal: true

class CustomUserdataType < ApplicationRecord
  audited

  has_many :custom_userdata, dependent: :destroy

  def self.permit!
    CustomUserdataType.pluck(:name, :custom_type).map do |name, kind|
      if kind == 'array'
        { name.to_sym => [] }
      else
        name.to_sym
      end
    end
  end
end
