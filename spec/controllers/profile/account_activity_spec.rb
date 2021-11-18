# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Profile::AccountActivityController, type: :controller do
  let(:user) do
    user = User.create!(username: 'example', email: 'test@localhost', password: 'test123456')
    user.confirm!
    user
  end
  let(:app) do
    Application.create!(
      uid: 'test',
      internal: true,
      redirect_uri: 'https://example.com',
      name: 'this is a fairly high entropy test string'
    )
  end

  context 'index' do
    render_views
    before do
      sign_in(user)
    end

    it 'shows logins' do
      Login.create!(
        user: user,
        service_provider: app,
        auth_type: 'Existing Login'
      )
      get :index
      expect(response.body).to include('Existing Login')
      expect(response.body).to include(app.name)
    end

    it 'updates user activity' do
      start = user.last_activity_at
      get :index
      user.reload
      expect(user.last_activity_at).not_to eq(start)
    end
  end
end
