# frozen_string_literal: true

class CustomGroupdatum < ApplicationRecord
  belongs_to :group
  belongs_to :custom_group_data_type

  serialize :value_raw, JSON

  delegate :name, to: :custom_group_data_type

  include Deserializable

  def value
    value_raw
  end

  def type
    custom_group_data_type.custom_type
  end

  def value=(new_value) # rubocop:disable Metrics/MethodLength
    new_value = deserialize(new_value, custom_group_data_type.custom_type)
    if custom_group_data_type
      valid = case custom_group_data_type.custom_type
              when 'boolean'
                new_value.is_a?(TrueClass) || new_value.is_a?(FalseClass)
              when 'array'
                new_value.is_a?(Array)
              when 'integer'
                new_value.is_a?(Integer)
              else
                true
              end
      raise "Invalid User Data: #{new_value} isn't an #{custom_group_data_type.custom_type}" unless valid
    end
    self.value_raw = new_value
  end
end
