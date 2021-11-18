# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Profile::ProfileController, type: :controller do
  let(:user) do
    user = User.create!(username: 'example', email: 'test@localhost', password: 'test123456')
    user.confirm!
    user
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
      expect(response.body).to include('id="custom_data_Has_pets" value="false" />')
    end
  end

  context 'update' do
    it 'updates custom attributes' do
      custom_bool
      post :update, params: { custom_data: { 'Has pets': true } }
      data = user.custom_userdata.first
      expect(data.name).to eq('Has pets')
      expect(data.value).to be true
    end

    it 'cannot update read-only attributes' do
      custom_bool.update(user_read_only: true)
      custom_datum = CustomUserdatum.where(
        user_id: user.id,
        custom_userdata_type: custom_bool
      ).first_or_initialize
      custom_datum.value = false
      custom_datum.save
      post :update, params: { custom_data: { 'Has pets': true } }
      data = user.custom_userdata.first
      expect(data.name).to eq('Has pets')
      expect(data.value).to be false
      custom_bool.update(user_read_only: false)
      post :update, params: { custom_data: { 'Has pets': true } }
      data = user.custom_userdata.first
      expect(data.name).to eq('Has pets')
      expect(data.value).to be true
    end
  end
end
