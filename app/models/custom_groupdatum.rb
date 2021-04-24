# frozen_string_literal: true

class CustomGroupdatum < ApplicationRecord
  audited

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

  def custom_data_type
    custom_group_data_type
  end

  def type_s
    'Group Data'
  end
end
