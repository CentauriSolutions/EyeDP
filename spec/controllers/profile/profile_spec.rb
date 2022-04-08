# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Profile::ProfileController, type: :controller do
  let(:user) do
    user = User.create!(username: 'example', email: 'test@localhost', password: 'test123456')
    user.confirm!
    user
  end
  let(:custom_bool) { CustomUserdataType.create(name: 'Has pets', custom_type: 'boolean') }
  let(:custom_string) { CustomUserdataType.create(name: 'Nickname', custom_type: 'string') }
  let(:custom_array) { CustomUserdataType.create(name: 'Nicknames', custom_type: 'array') }
  let(:custom_password) { CustomUserdataType.create(name: 'Demo password', custom_type: 'password') }

  before do
    sign_in(user)
  end

  context 'index' do
    render_views

    it 'shows custom attributes' do
      custom_bool
      get :index
      expect(response.body).to include('id="custom_data_Has_pets" value="false"')
    end
  end

  context 'update' do
    context 'boolean type' do
      before do
        custom_bool
      end

      it 'updates custom attributes' do
        post :update, params: { custom_data: { 'Has pets': true } }
        data = user.custom_userdata.first
        expect(data.name).to eq('Has pets')
        expect(data.value).to be true
      end

      it 'ignores invalid custom attributes' do
        post :update, params: { custom_data: { 'Has pets': 'indeed' } }
        expect(user.custom_userdata.count).to eq(0)
        expect(flash[:error]).to match('Failed to update userdata, invalid value')
      end

      it 'deleted custom attributes' do
        CustomUserdatum.where(
          user_id: user.id,
          custom_userdata_type: custom_bool,
          value_raw: true
        ).first_or_create
        expect(user.custom_userdata.count).to eq(1)
        post :update, params: { custom_data: { 'Has pets': nil } }
        expect(user.custom_userdata.count).to eq(0)
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

    context 'string type' do
      before do
        custom_string
      end

      it 'updates custom attributes' do
        post :update, params: { custom_data: { 'Nickname': 'new nick' } }
        data = user.custom_userdata.first
        expect(data.name).to eq('Nickname')
        expect(data.value).to eq('new nick')
      end

      it 'deleted custom attributes' do
        CustomUserdatum.where(
          user_id: user.id,
          custom_userdata_type: custom_string,
          value_raw: 'thingy'
        ).first_or_create
        expect(user.custom_userdata.count).to eq(1)
        post :update, params: { custom_data: { 'Nickname': nil } }
        expect(user.custom_userdata.count).to eq(0)
      end

      it 'cannot update read-only attributes' do
        custom_string.update(user_read_only: true)
        custom_datum = CustomUserdatum.where(
          user_id: user.id,
          custom_userdata_type: custom_string
        ).first_or_initialize
        custom_datum.value = 'locked nick'
        custom_datum.save
        post :update, params: { custom_data: { 'Nickname': 'new nick' } }
        data = user.custom_userdata.first
        expect(data.name).to eq('Nickname')
        expect(data.value).to eq('locked nick')
        custom_string.update(user_read_only: false)
        post :update, params: { custom_data: { 'Nickname': 'new nick' } }
        data = user.custom_userdata.first
        expect(data.name).to eq('Nickname')
        expect(data.value).to eq('new nick')
      end
    end

    context 'array type' do
      before do
        custom_array
      end

      it 'updates custom attributes' do
        post :update, params: { custom_data: { 'Nicknames': %w[nick1 nick2] } }
        data = user.custom_userdata.first
        expect(data.name).to eq('Nicknames')
        expect(data.value).to eq(%w[nick1 nick2])
      end

      it 'deleted custom attributes' do
        CustomUserdatum.where(
          user_id: user.id,
          custom_userdata_type: custom_array,
          value_raw: 'thingy'
        ).first_or_create
        expect(user.custom_userdata.count).to eq(1)
        post :update, params: { custom_data: { 'Nicknames': [nil], 'ignored': true } }
        expect(user.custom_userdata.count).to eq(0)
      end
    end

    context 'password type' do
      before do
        custom_password
      end

      it 'updates custom attributes' do
        post :update, params: { custom_data: { 'Demo password': 'new password' } }
        data = user.custom_userdata.first
        expect(data.name).to eq('Demo password')

        expect(User.new(encrypted_password: data.value).valid_password?('new password')).to be true
      end

      it 'deleted custom attributes' do
        CustomUserdatum.where(
          user_id: user.id,
          custom_userdata_type: custom_password,
          value_raw: 'thingy'
        ).first_or_create
        expect(user.custom_userdata.count).to eq(1)
        post :update, params: { custom_data: { 'Demo password': nil } }
        expect(user.custom_userdata.count).to eq(0)
      end

      it 'cannot update read-only attributes' do
        custom_password.update(user_read_only: true)
        custom_datum = CustomUserdatum.where(
          user_id: user.id,
          custom_userdata_type: custom_password
        ).first_or_initialize
        custom_datum.value = 'locked password'
        custom_datum.save
        post :update, params: { custom_data: { 'Demo password': 'new password' } }
        data = user.custom_userdata.first
        expect(data.name).to eq('Demo password')
        expect(User.new(encrypted_password: data.value).valid_password?('locked password')).to be true
        expect(User.new(encrypted_password: data.value).valid_password?('new password')).to be false
        custom_password.update(user_read_only: false)
        post :update, params: { custom_data: { 'Demo password': 'new password' } }
        data = user.custom_userdata.first
        expect(data.name).to eq('Demo password')
        expect(User.new(encrypted_password: data.value).valid_password?('new password')).to be true
      end
    end
  end
end
