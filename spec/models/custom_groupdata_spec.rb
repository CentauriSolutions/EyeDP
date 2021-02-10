# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CustomGroupdatum, type: :model do
  let(:custom_type) { CustomGroupDataType.create(name: 'alias', custom_type: 'string') }
  let(:group) { Group.create!(name: 'root') }

  it { should be_audited }

  it 'A user can have a custom user data' do
    data = CustomGroupdatum.create!(group: group, custom_group_data_type: custom_type, value: 'ahoy')
    expect(data.name).to eq('alias')
    expect(data.value).to eq('ahoy')
  end
end
