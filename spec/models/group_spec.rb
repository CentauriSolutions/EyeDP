# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Group, type: :model do
  let(:root_group) { Group.create!(name: 'root') }
  let(:child_group) { Group.create!(name: 'child', parent: root_group) }

  let(:permission) { Permission.create!(name: 'test permission') }

  it 'inherits permissions' do
    root_group.permissions << permission
    expect(child_group.effective_permissions).to include permission
  end
end
