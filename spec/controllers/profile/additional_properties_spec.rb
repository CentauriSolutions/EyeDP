# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Profile::AdditionalPropertiesController, type: :controller do # rubocop:disable Metrics/BlockLength
  let(:user) do
    User.create!(
      username: 'example',
      email: 'test@localhost',
      password: 'test1234'
    )
  end
  let(:custom_bool) { CustomUserdataType.create(name: 'Has pets', custom_type: 'boolean') }

  before do
    sign_in(user)
  end

  context 'index' do
    render_views

    it 'shows custom attributes' do
      custom_bool
      get :index
      expect(response.body).to include('id="custom_userdata_Has_pets" value="false" />')
    end
  end

  context 'update' do
    it 'updates custom attributes' do
      custom_bool
      post :update, params: { custom_userdata: { 'Has pets': true } }
      data = user.custom_userdata.first
      expect(data.name).to eq('Has pets')
      expect(data.value).to be true
    end
  end
end
