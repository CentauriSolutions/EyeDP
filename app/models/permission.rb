# frozen_string_literal: true

# == Schema Information
#
# Table name: permissions
#
#  id          :uuid             not null, primary key
#  description :text
#  name        :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Permission < ApplicationRecord
  has_many :group_permissions, dependent: :destroy

  def to_s
    name
  end
end
