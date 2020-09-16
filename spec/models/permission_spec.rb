# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Permission, type: :model do
  let(:permission) { Permission.create!(name: 'test permission') }

  it 'uses name as to_s' do
    expect(permission.to_s).to eq 'test permission'
  end
end
