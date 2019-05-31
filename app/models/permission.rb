class Permission < ApplicationRecord
  has_many :group_permissions
end
