# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegistrationsController, type: :controller do
  include DeviseHelpers
  let(:user) do
    user = User.create!(username: 'example', email: 'test@localhost', password: 'test1234')
    user.confirm!
    user
  end

  before do
    set_devise_mapping(context: @request)
    sign_in(user)
  end

  context 'with permenant email' do
    before do
      Setting.permanent_email = true
    end

    it 'can edit name' do
      patch(:update, params: { id: user.id, user: { name: 'test', current_password: 'test1234' } })
      expect(response.status).to eq(302)
      user.reload
      expect(user.name).to eq('test')
    end

    it 'cannot edit email' do
      patch(:update, params: { id: user.id, user: { email: 'test2@localhost', current_password: 'test1234' } })
      expect(response.status).to eq(302)
      user.reload
      expect(user.email).to eq('test@localhost')
    end
  end

  context 'without permenant email' do
    before do
      Setting.permanent_email = false
    end

    it 'can edit name' do
      patch(:update, params: { id: user.id, user: { name: 'test', current_password: 'test1234' } })
      expect(response.status).to eq(302)
      user.reload
      expect(user.name).to eq('test')
    end

    it 'can edit email' do
      patch(:update, params: { id: user.id, user: { email: 'test2@localhost', current_password: 'test1234' } })
      expect(response.status).to eq(302)
      user.reload
      expect(user.email).to eq('test2@localhost')
    end
  end
end
