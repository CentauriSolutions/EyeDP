# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :inet
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :inet
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

require 'rails_helper'
require 'devise_two_factor/spec_helpers'

RSpec.describe User, type: :model do
  include ActiveJob::TestHelper

  let(:user) { User.create!(username: 'example', email: 'test@localhost', password: 'test1234') }
  let(:group) { Group.create!(name: 'administrators', admin: true) }
  let(:operator_group) { Group.create!(name: 'operators', operator: true) }
  let(:manager_group) { Group.create!(name: 'managers', manager: true) }

  it { should be_audited }

  it 'makes a user Admin is it has membership' do
    expect(user.admin?).to be false
    user.groups << group
    expect(user.admin?).to be true
  end

  it 'makes a user Operator if it has membership' do
    expect(user.operator?).to be false
    user.groups << operator_group
    expect(user.operator?).to be true
  end

  it 'makes the user Manager if it has membership' do
    expect(user.manager?).to be false
    user.groups << manager_group
    expect(user.manager?).to be true
  end

  it 'does not grant admin just because of a group name' do
    group.admin = false
    user.groups << group
    expect(user.admin?).to be false
  end

  it 'can require an admin to have 2fa before adding' do
    group.update({ requires_2fa: true })
    user.groups << group
    expect(user.admin?).to be false
    user.update({ otp_required_for_login: true })
    expect(user.admin?).to be true
  end

  it 'does not make a non-admin an admin' do
    expect(user.admin?).to be false
  end

  it 'prefers username for to_s' do
    expect(user.to_s).to eq 'example'
  end

  it 'falls back to email for to_s' do
    user.username = nil
    expect(user.to_s).to eq 'test@localhost'
  end

  it 'prefers username for login' do
    expect(user.login).to eq 'example'
  end

  it 'falls back to email for login' do
    user.username = nil
    expect(user.login).to eq 'test@localhost'
  end

  it 'can overwrite login' do
    user.login = 'example2'
    expect(user.login).to eq 'example2'
  end

  it 'can be expired' do
    user.update!(expires_at: 10.minutes.ago)
    expect(user.expired?).to be true
  end

  it 'only changes password when encrypted_password is nil' do
    user.password = nil
    expect(user.valid_password?('test1234')).to be true
    user.save
    expect(user.valid_password?('test1234')).to be true
    old_encrypted = user.encrypted_password
    user.encrypted_password = nil
    user.save
    expect(user.encrypted_password).not_to eq(old_encrypted)
  end

  context 'Expirable' do
    context 'expire_after 30 days' do
      before do
        Setting.expire_after = 30.days
      end
      after do
        Setting.expire_after = nil
      end
      it 'expires a user' do
        expect(user.expired?).to be false
        user.last_activity_at = 31.days.ago
        expect(user.expired?).to be true
      end

      it 'allows unexpired users' do
        expect(user.expired?).to be false
        user.last_activity_at = 10.days.ago
        expect(user.expired?).to be false
      end
    end

    context 'expire_after nil' do
      before do
        Setting.expire_after = nil
      end
      it 'expires a user' do
        expect(user.expired?).to be false
        user.last_activity_at = 2.years.ago
        expect(user.expired?).to be false
      end
    end
  end

  context 'Emails' do
    context 'A group with a welcome email' do
      let(:test_group) { Group.create!(name: 'test_group', welcome_email: 'Hey!') }

      it 'Sends a welcome email when a user is added to the group' do
        expect do
          perform_enqueued_jobs do
            user.groups << test_group
          end
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context 'A group without a welcome email' do
      let(:test_group) { Group.create!(name: 'test_group') }

      it 'Does not send a welcome email when a user is added to the group' do
        expect do
          perform_enqueued_jobs do
            user.groups << test_group
          end
        end.not_to(change { ActionMailer::Base.deliveries.count })
      end
    end

    context 'A group with an empty welcome email' do
      let(:test_group) { Group.create!(name: 'test_group', welcome_email: '') }

      it 'Does not send a welcome email when a user is added to the group' do
        expect do
          perform_enqueued_jobs do
            user.groups << test_group
          end
        end.not_to(change { ActionMailer::Base.deliveries.count })
      end
    end
  end

  it 'sends a password reset email with a forced reset' do
    expect do
      perform_enqueued_jobs do
        user.force_password_reset!
      end
    end.to change { ActionMailer::Base.deliveries.count }.by(1)
  end
  it_behaves_like 'two_factor_authenticatable'
  it_behaves_like 'two_factor_backupable'

  context 'webhooks' do
    let(:create_webhook) { WebHook.create!(url: 'https://example.com', user_create_events: true) }
    let(:update_webhook) { WebHook.create!(url: 'https://example.com', user_update_events: true) }
    let(:delete_webhook) { WebHook.create!(url: 'https://example.com', user_destroy_events: true) }

    it 'queues a webhook on create' do
      create_webhook
      expect do
        User.create!(email: 'test@example.com', username: 'test_user', password: 'test1234')
      end.to change(NotificationSetupWorker.jobs, :size).by(1)
    end

    it 'queues a webhook on update' do
      update_webhook
      user
      expect do
        user.update!(username: 'testing')
      end.to change(NotificationSetupWorker.jobs, :size).by(1)
    end

    it 'queues a webhook on delete' do
      delete_webhook
      user
      expect do
        user.destroy
      end.to change(NotificationSetupWorker.jobs, :size).by(1)
    end

    context 'group membership' do
      let(:create_webhook) { WebHook.create!(url: 'https://example.com', group_membership_create_events: true) }
      let(:delete_webhook) { WebHook.create!(url: 'https://example.com', group_membership_destroy_events: true) }

      it 'queues a webhook on group membership create' do
        create_webhook
        user
        group
        expect(user.groups).to eq []
        expect do
          user.groups << group
          expect(user.groups).to eq [group]
        end.to change(NotificationSetupWorker.jobs, :size).by(1)
      end

      it 'queues a webhook on group membership delete' do
        delete_webhook
        user.groups << group
        expect(user.groups).to eq [group]
        expect do
          user.groups = []
          expect(user.groups).to eq []
        end.to change(NotificationSetupWorker.jobs, :size).by(1)
      end
    end
  end
end
