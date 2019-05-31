# == Schema Information
#
# Table name: groups
#
#  id         :uuid             not null, primary key
#  name       :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  parent_id  :bigint
#
# Indexes
#
#  index_groups_on_parent_id  (parent_id)
#

class Group < ApplicationRecord
  belongs_to :parent,
             :foreign_key => "parent_id",
             :class_name => "Group",
             optional: true

  has_many :groups,
           :foreign_key => 'parent_id',
           :class_name => 'Group',
           # :order => 'created_at ASC',
           :dependent => :delete_all

  has_many :group_permissions
  has_many :permissions, through: :group_permissions

  has_many :user_groups
  has_many :users, through: :user_groups
end
