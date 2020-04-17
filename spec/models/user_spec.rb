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

RSpec.describe User, type: :model do
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
end
