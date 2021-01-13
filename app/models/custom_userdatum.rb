# frozen_string_literal: true

class CustomUserdatum < ApplicationRecord
  belongs_to :user
  belongs_to :custom_userdata_type
  serialize :value_raw, JSON

  delegate :name, to: :custom_userdata_type

  include Deserializable

  def value
    value_raw
  end

  def type
    custom_userdata_type.custom_type
  end

  def value=(new_value) # rubocop:disable Metrics/MethodLength
    new_value = deserialize(new_value, custom_userdata_type.custom_type)
    if custom_userdata_type
      valid = case custom_userdata_type.custom_type
              when 'boolean'
                new_value.is_a?(TrueClass) || new_value.is_a?(FalseClass)
              when 'array'
                new_value.is_a?(Array)
              when 'integer'
                new_value.is_a?(Integer)
              else
                true
              end
      raise "Invalid User Data: #{new_value} isn't an #{custom_userdata_type.custom_type}" unless valid
    end
    self.value_raw = new_value
  end
end
