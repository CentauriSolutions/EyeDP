# frozen_string_literal: true

module Deserializable
  SEPARATOR_REGEXP = /[\n,;]+/.freeze

  # takes a string and returns a typed thing
  def deserialize(value, custom_type) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    case custom_type
    when 'boolean'
      return nil unless ['t', 'true', '1', 1, true, :true, 'f', 'false', '0', 0, false, :false].include? value #  rubocop:disable Lint/BooleanSymbol

      ['t', 'true', '1', 1, true, :true].include?(value) #  rubocop:disable Lint/BooleanSymbol
    when 'array'
      return value if value.is_a?(Array)

      (value || '').split(SEPARATOR_REGEXP).map(&:strip).reject(&:empty?) || nil
    when 'integer'
      begin
        value.to_i
      rescue NomethodError
        nil
      end
    else
      value
    end
  end

  def value=(new_value) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    if custom_data_type
      new_value = deserialize(new_value, type)
      valid = case type
              when 'boolean'
                new_value.is_a?(TrueClass) || new_value.is_a?(FalseClass)
              when 'array'
                is_array = new_value.is_a?(Array)
                new_value = new_value.reject(&:empty?) if is_array
                is_array
              when 'integer'
                new_value.is_a?(Integer)
              when 'string', 'password'
                raise "Invalid Data: #{new_value} isn't a string" unless new_value.is_a? String

                true
              else
                false
              end
      raise "Invalid #{type_s}: #{new_value} isn't an #{type}" unless valid
    end
    new_value = User.new(password: new_value).encrypted_password if type == 'password' && new_value != value_raw
    self.value_raw = new_value
  end
end
