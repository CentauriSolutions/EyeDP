# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CustomUserdatum, type: :model do
  let(:custom_bool) { CustomUserdataType.create(name: 'has_pets', custom_type: 'boolean') }
  let(:user) { User.create!(username: 'example', email: 'test@localhost', password: 'test123456') }

  it { should be_audited }

  it 'A user can have a custom user data' do
    data = CustomUserdatum.create!(user: user, custom_userdata_type: custom_bool, value: false)
    expect(data.name).to eq('has_pets')
    expect(data.value).to be false
  end
end
