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

  let(:user) do
    u = User.new(username: 'example', email: 'test@localhost', password: 'test123456')
    u.emails[0].confirmed_at = Time.now.utc
    u.save!
    u
  end

  let(:group) { Group.create!(name: 'administrators', admin: true) }
  let(:operator_group) { Group.create!(name: 'operators', operator: true) }
  let(:manager_group) { Group.create!(name: 'managers', manager: true) }

  it { should be_audited }

  it 'makes a user Admin is it has membership' do
    expect(user.admin?).to be false
    user.groups << group
    this_user = User.find(user.id)
    expect(this_user.admin?).to be true
  end

  it 'makes a user Operator if it has membership' do
    expect(user.operator?).to be false
    user.groups << operator_group
    this_user = User.find(user.id)
    expect(this_user.operator?).to be true
  end

  it 'makes the user Manager if it has membership' do
    expect(user.manager?).to be false
    user.groups << manager_group
    this_user = User.find(user.id)
    expect(this_user.manager?).to be true
  end

  it 'does not grant admin just because of a group name' do
    group.admin = false
    user.groups << group
    this_user = User.find(user.id)
    expect(this_user.admin?).to be false
  end

  it 'can require an admin to have 2fa before adding' do
    group.update({ requires_2fa: true })
    user.groups << group
    this_user = User.find(user.id)
    expect(this_user.admin?).to be false
    this_user = User.find(user.id)
    this_user.update({ otp_required_for_login: true })
    expect(this_user.admin?).to be true
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

  it 'can be disabled' do
    user.update!(disabled_at: 10.minutes.ago)
    expect(user.disabled?).to be true
  end

  it 'only changes password when encrypted_password is nil' do
    user.password = nil
    expect(user.valid_password?('test123456')).to be true
    user.save
    expect(user.valid_password?('test123456')).to be true
    old_encrypted = user.encrypted_password
    user.encrypted_password = nil
    user.save
    expect(user.encrypted_password).not_to eq(old_encrypted)
  end

  it 'cannot have spaces in the username' do
    user.username = 'user name'
    expect(user.valid?).to be false
    expect(user.errors.first.attribute).to eq :username
  end

  it 'does not allow usernames to overlap emails' do
    user
    user2 = User.new(username: 'test@localhost', email: 'test2@localhost', password: 'test123456')

    expect(user2.valid?).to be false
    expect(user2.errors.first.attribute).to eq :username
    expect(user2.errors.first.message).to eq 'is invalid'
  end

  it 'does not allow usernames to include content types' do
    user.username = 'test.html'
    expect(user.valid?).to be false
    expect(user.errors.first.attribute).to eq :username
    expect(user.errors.first.message).to eq 'ending with a reserved file extension is not allowed.'
  end

  it 'allows numbers after first charater in usernames' do
    user.username = 'test1'
    expect(user.valid?).to be true
  end

  it 'allows hyphen, underscore, and period after first character in usernames' do
    user.username = 'test-_.'
    expect(user.valid?).to be true
  end

  it 'does not allow interesting characters in usernames' do
    user.username = 'test_øåé'
    expect(user.valid?).to be false
    expect(user.errors.first.attribute).to eq :username
    expect(user.errors.first.message).to(
      eq 'must contain only basic letters, numbers, -, and _; and start with a letter.'
    )
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
        User.create!(email: 'test@example.com', username: 'test_user', password: 'test123456')
      end.to change(NotificationSetupWorker.jobs, :size).by(1)
    end

    it 'queues a webhook on update' do
      update_webhook
      user
      expect do
        user.update!(username: 'testing')
      end.to change(NotificationSetupWorker.jobs, :size).by(1)
    end

    it 'does not queue a webhook on update of updated_at' do
      update_webhook
      user
      expect do
        user.update!(updated_at: Time.zone.now)
      end.not_to change(NotificationSetupWorker.jobs, :size)
    end

    it 'does not queue a webhook on update of last_activity_at' do
      update_webhook
      user
      expect do
        user.update!(last_activity_at: Time.zone.now)
      end.not_to change(NotificationSetupWorker.jobs, :size)
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
