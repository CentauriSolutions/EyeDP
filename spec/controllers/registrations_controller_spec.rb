# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegistrationsController, type: :controller do
  include DeviseHelpers
  let(:user) do
    user = User.create!(username: 'example', email: 'test@localhost', password: 'test123456')
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
      patch(:update, params: { id: user.id, user: { name: 'test', current_password: 'test123456' } })
      expect(response.status).to eq(302)
      user.reload
      expect(user.name).to eq('test')
    end

    it 'cannot edit email' do
      patch(:update, params: { id: user.id, user: { email: 'test2@localhost', current_password: 'test123456' } })
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
      patch(:update, params: { id: user.id, user: { name: 'test', current_password: 'test123456' } })
      expect(response.status).to eq(302)
      user.reload
      expect(user.name).to eq('test')
    end

    it 'can edit email' do
      Email.create(user:, email: 'test2@localhost', confirmed_at: Time.zone.now)
      patch(:update, params: { id: user.id, user: { email: 'test2@localhost', current_password: 'test123456' } })
      expect(response.status).to eq(302)
      user.reload
      expect(user.email).to eq('test2@localhost')
    end

    it 'cannot set email to an unconfirmed email' do
      Email.create(user:, email: 'test2@localhost')
      patch(:update, params: { id: user.id, user: { email: 'test2@localhost', current_password: 'test123456' } })
      expect(response.status).to eq(302)
      user.reload
      expect(user.email).to eq('test@localhost')
    end
  end
end
