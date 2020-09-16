# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PagesController, type: :controller do
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
      get :user_dashboard
      expect(response.body).to include('this is a fairly high entropy test string')
    end
  end
end
