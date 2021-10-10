# frozen_string_literal: true

class ApiKey < ApplicationRecord
  audited

  after_initialize :set_key

  def matching_custom_data(data)
    return false if custom_data.nil?

    data = Array(data)
    custom_data.intersection(data) == data
  end

  def to_s
    name
  end

  protected

  def set_key
    self.key ||= SecureRandom.hex(48)
  end
end
