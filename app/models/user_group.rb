# == Schema Information
#
# Table name: user_groups
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  group_id   :uuid
#  user_id    :uuid
#
# Indexes
#
#  index_user_groups_on_group_id  (group_id)
#  index_user_groups_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (group_id => groups.id)
#  fk_rails_...  (user_id => users.id)
#

class UserGroup < ApplicationRecord
  belongs_to :user
  belongs_to :group
end
