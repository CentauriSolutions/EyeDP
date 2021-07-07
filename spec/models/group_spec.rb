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

  it { should be_audited }

  it 'inherits permissions' do
    root_group.permissions << permission
    expect(child_group.effective_permissions).to include permission
  end

  it 'uses name for to_s' do
    expect(root_group.to_s).to eq 'root'
  end

  context 'webhooks' do
    let(:create_webhook) { WebHook.create!(url: 'https://example.com', user_create_events: true) }
    let(:update_webhook) { WebHook.create!(url: 'https://example.com', user_update_events: true) }
    let(:delete_webhook) { WebHook.create!(url: 'https://example.com', user_destroy_events: true) }

    it 'queues a webhook on create' do
      create_webhook
      expect do
        root_group
      end.to change(NotificationSetupWorker.jobs, :size).by(1)
    end

    it 'queues a webhook on update' do
      update_webhook
      root_group
      expect do
        root_group.update!(name: 'root2')
      end.to change(NotificationSetupWorker.jobs, :size).by(1)
    end

    it 'queues a webhook on delete' do
      delete_webhook
      root_group
      expect do
        root_group.destroy
      end.to change(NotificationSetupWorker.jobs, :size).by(1)
    end
  end
end
