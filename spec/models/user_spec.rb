# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
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
  let(:user) { User.create!(email: 'test@localhost', password: 'test1234') }
  let(:group) { Group.create!(name: 'administrators') }

  it 'makes a user Admin is it has membership' do
    user.groups << group
    expect(user.admin?).to be true
  end

  it 'does not make a non-admin an admin' do
    expect(user.admin?).to be false
  end
end
