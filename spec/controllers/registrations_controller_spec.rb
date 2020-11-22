# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegistrationsController, type: :controller do
  include DeviseHelpers
  let(:user) { User.create!(username: 'example', email: 'test@localhost', password: 'test1234') }

  before do
    set_devise_mapping(context: @request)
    sign_in(user)
  end

  context 'with permenant usernames' do
    before do
      Setting.permemant_username = true
    end

    it 'can edit name' do
      patch(:update, params: { id: user.id, user: { name: 'test', current_password: 'test1234' } })
      expect(response.status).to eq(302)
      user.reload
      expect(user.name).to eq('test')
    end

    it 'cannot edit username' do
      patch(:update, params: { id: user.id, user: { username: 'test', current_password: 'test1234' } })
      expect(response.status).to eq(302)
      user.reload
      expect(user.username).to eq('example')
    end
  end

  context 'without permenant usernames' do
    before do
      Setting.permemant_username = false
    end

    it 'can edit name' do
      patch(:update, params: { id: user.id, user: { name: 'test', current_password: 'test1234' } })
      expect(response.status).to eq(302)
      user.reload
      expect(user.name).to eq('test')
    end

    it 'can edit username' do
      patch(:update, params: { id: user.id, user: { username: 'test', current_password: 'test1234' } })
      expect(response.status).to eq(302)
      user.reload
      expect(user.username).to eq('test')
    end
  end
end
