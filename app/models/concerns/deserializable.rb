# frozen_string_literal: true

module Deserializable
  SEPARATOR_REGEXP = /[\n,;]+/.freeze

  # takes a string and returns a typed thing
  def deserialize(value, custom_type)
    case custom_type
    when 'boolean'
      ['t', 'true', '1', 1, true, :true].include?(value) #  rubocop:disable Lint/BooleanSymbol
    when 'array'
      (value || '').split(SEPARATOR_REGEXP).map(&:strip).reject(&:empty?)
    when 'integer'
      value.to_i
    else
      value
    end
  end
end
