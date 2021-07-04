# frozen_string_literal: true

# == Schema Information
#
# Table name: groups
#
#  id         :uuid             not null, primary key
#  name       :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  parent_id  :uuid
#
# Indexes
#
#  index_groups_on_parent_id  (parent_id)
#

class Group < ApplicationRecord
  extend Notifiable

  audited

  acts_as_tree order: 'name'
  belongs_to :parent,
             class_name: 'Group',
             optional: true

  has_many :groups,
           foreign_key: 'parent_id',
           class_name: 'Group',
           # :order => 'created_at ASC',
           dependent: :delete_all

  has_many :group_permissions, dependent: :destroy
  has_many :permissions, through: :group_permissions # , via: :test
  # 'SELECT DISTINCT people.* ' +
  # 'FROM people p, post_subscriptions ps ' +
  # 'WHERE ps.post_id = #{id} AND ps.person_id = p.id ' +
  # 'ORDER BY p.first_name'
  # 'SELECT "permissions".*
  #  FROM "permissions"
  #  INNER JOIN "group_permissions"
  #  ON "permissions"."id" = "group_permissions"."permission_id"
  #  WHERE "group_permissions"."group_id" IN #{ancestors.pluck(:id) << id}' }

  has_many :user_groups, dependent: :destroy
  has_many :users, through: :user_groups, dependent: :destroy

  has_many :custom_groupdata, dependent: :destroy

  notify_for %i[create update destroy]

  def to_s
    name
  end

  def effective_permissions
    Permission.joins(:group_permissions).where(group_permissions: { group_id: ancestors.pluck(:id) << id })
  end

  def template
    @template ||= Liquid::Template.parse(welcome_email)
  end

  def template_variables(user = nil) # rubocop:disable Metrics/MethodLength
    h = {
      'group' => {
        'name' => name
      }
    }
    if user
      h['user'] = {
        'username' => user.username,
        'email' => user.email
      }
    end
    h
  end

  def rendered_welcome_email(user = nil)
    template.render(template_variables(user))
  end

  def roles
    @roles ||=
      %i[admin manager operator].filter do |name|
        send(name)
      end
  end
end
