# frozen_string_literal: true

class ApiKey < ApplicationRecord
  after_initialize :set_key

  CAPABILITIES = {
    list_groups: 1,
    read_group: 2,
    write_group: 4,
    list_users: 8,
    read_user: 16,
    write_user: 32,
    read_group_members: 64,
    write_group_members: 128,
    control_admin_groups: 256,
    read_custom_data: 512,
    write_custom_data: 1024
  }.with_indifferent_access

  CAPABILITIES.each do |cap, bit|
    define_method("#{cap}?") do
      capabilities_mask & bit == bit
    end

    define_method("#{cap}!") do
      self.capabilities_mask |= bit
    end
  end

  def capabilities
    CAPABILITIES.filter { |_cap, bit| self.capabilities_mask & bit == bit }.map { |cap, _bit| cap }
  end

  def capabilities=(caps)
    self.capabilities_mask = Array.wrap(caps)
                                  .filter(&:present?)
                                  .map { |cap| CAPABILITIES[cap] }
                                  .reduce(0) { |m, b| m | b }
  end

  def matching_custom_data(data)
    return false if custom_data.nil?

    data = Array(data)
    custom_data.intersection(data) == data
  end

  protected

  def set_key
    self.key ||= SecureRandom.hex(48)
  end
end
