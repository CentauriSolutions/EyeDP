# frozen_string_literal: true

class CustomUserdatum < ApplicationRecord
  audited

  belongs_to :user
  belongs_to :custom_userdata_type
  serialize :value_raw, JSON

  delegate :name, to: :custom_userdata_type
  delegate :user_read_only, to: :custom_userdata_type

  alias read_only user_read_only

  include Deserializable

  def value
    value_raw
  end

  def type
    custom_userdata_type.custom_type
  end

  def custom_data_type
    custom_userdata_type
  end

  def type_s
    'User Data'
  end
end
