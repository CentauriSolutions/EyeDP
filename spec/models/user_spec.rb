# frozen_string_literal: true

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
