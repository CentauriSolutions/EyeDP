# == Schema Information
#
# Table name: group_permissions
#
#  id            :uuid             not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  group_id      :uuid
#  permission_id :uuid
#
# Indexes
#
#  index_group_permissions_on_group_id       (group_id)
#  index_group_permissions_on_permission_id  (permission_id)
#
# Foreign Keys
#
#  fk_rails_...  (group_id => groups.id)
#  fk_rails_...  (permission_id => permissions.id)
#

class GroupPermission < ApplicationRecord
  belongs_to :group
  belongs_to :permission
end
