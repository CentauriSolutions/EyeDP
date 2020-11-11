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
  let(:group) { Group.create!(name: 'administrators') }

  it 'makes a user Admin is it has membership' do
    user.groups << group
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
  end

  it_behaves_like 'two_factor_authenticatable'
  it_behaves_like 'two_factor_backupable'
end
