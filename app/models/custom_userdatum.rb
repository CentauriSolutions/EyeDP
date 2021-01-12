# frozen_string_literal: true

class CustomUserdatum < ApplicationRecord
  belongs_to :user
  belongs_to :custom_userdata_type
  serialize :value_raw, JSON

  SEPARATOR_REGEXP = /[\n,;]+/.freeze

  delegate :name, to: :custom_userdata_type

  def value
    value_raw
  end

  def type
    custom_userdata_type.custom_type
  end

  def value=(new_value) # rubocop:disable Metrics/MethodLength
    new_value = deserialize(new_value)
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

  private

  # takes a string and returns a typed thing
  def deserialize(value)
    case custom_userdata_type.custom_type
    when 'boolean'
      ['t', 'true', '1', 1, true].include?(value)
    when 'array'
      (value || '').split(SEPARATOR_REGEXP).map(&:strip).reject(&:empty?)
    when 'integer'
      value.to_i
    else
      value
    end
  end
end
