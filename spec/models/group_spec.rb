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

require 'rails_helper'

RSpec.describe Group, type: :model do
  let(:root_group) { Group.create!(name: 'root') }
  let(:child_group) { Group.create!(name: 'child', parent: root_group) }

  let(:permission) { Permission.create!(name: 'test permission') }

  it 'inherits permissions' do
    root_group.permissions << permission
    expect(child_group.effective_permissions).to include permission
  end

  it 'uses name for to_s' do
    expect(root_group.to_s).to eq 'root'
  end
end
