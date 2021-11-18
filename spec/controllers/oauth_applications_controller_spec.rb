# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OauthApplicationsController, type: :controller do
  let(:user) do
    user = User.create!(username: 'example', email: 'test@localhost', password: 'test123456')
    user.confirm!
    user
  end
  let(:app) { Application.create!(uid: 'test', internal: true, redirect_uri: 'https://example.com', name: 'test') }
  let(:params) do
    {
      response_type: 'code',
      client_id: app.uid,
      redirect_uri: app.redirect_uri,
      state: 'state'
    }
  end

  context 'signed in user' do
    before do
      sign_in(user)
    end

    context 'with sudo enabled' do
      render_views
      before do
        Setting.sudo_for_sso = true
        Setting.sudo_enabled = true
      end
      after do
        Setting.sudo_for_sso = false
        Setting.sudo_enabled = false
      end
      describe 'New login' do
        it 'updates user activity' do
          start = user.last_activity_at
          get :create, params: params
          user.reload
          expect(user.last_activity_at).not_to eq(start)
        end

        it 'records the login' do
          # @request.env['devise.mapping'] = Devise.mappings[:user]
          get :create, params: params
          expect(response.status).to eq(200)
          expect(Login.count).to eq 0
          expect(response.body).to include 'Confirm password to continue'
        end
      end
    end
    context 'with sudo disabled' do
      before do
        Setting.sudo_for_sso = false
        Setting.sudo_enabled = false
      end
      describe 'Existing Login' do
        it 'updates user activity' do
          start = user.last_activity_at
          get :create, params: params
          user.reload
          expect(user.last_activity_at).not_to eq(start)
        end

        it 'records the login' do
          # @request.env['devise.mapping'] = Devise.mappings[:user]
          get :create, params: params
          expect(response.status).to eq(302)
          expect(Login.count).to eq 1
        end
      end

      describe 'New login' do
        it 'updates user activity' do
          start = user.last_activity_at
          get :create, params: params
          user.reload
          expect(user.last_activity_at).not_to eq(start)
        end

        it 'records the login' do
          # @request.env['devise.mapping'] = Devise.mappings[:user]
          get :create, params: params
          expect(response.status).to eq(302)
          expect(Login.count).to eq 1
        end
      end

      describe 'with a group restriction' do
        let(:other_group) { Group.create!(name: 'users2') }
        let(:app) do
          app = Application.create!(uid: 'test', internal: true, redirect_uri: 'https://example.com', name: 'test',
                                    scopes: 'openid')
          app.groups << other_group
          app
        end

        it 'does not grant access' do
          get :create, params: params
          expect(flash[:notice]).to match('You are not authorized to access this application.')
          user.reload
        end
      end
    end
  end

  context 'signed out user' do
    it 'returns 301 code and redirects to login' do
      get :new
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to eq('http://test.host/users/sign_in')
    end
  end
end
