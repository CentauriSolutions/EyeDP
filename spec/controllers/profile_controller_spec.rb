# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProfileController, type: :controller do
  let(:user) { User.create!(username: 'example', email: 'test@localhost', password: 'test1234') }
  let(:app) do
    Application.create!(
      uid: 'test',
      internal: true,
      redirect_uri: 'https://example.com',
      name: 'this is a fairly high entropy test string'
    )
  end

  context 'User dashboard' do
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
      get :show
      expect(response.body).to include('this is a fairly high entropy test string')
    end

    it 'blocks expired users' do
      user.update!(expires_at: 10.minutes.ago)

      get :show
      expect(flash[:alert])
        .to match(/account is expired/)
      expect(response.body).to include('redirected')
    end

    it 'updates user activity' do
      start = user.last_activity_at
      get :show
      user.reload
      expect(user.last_activity_at).not_to eq(start)
    end
  end
end
