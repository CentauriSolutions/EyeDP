# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BasicAuthController, type: :controller do
  let(:user) do
    user = User.create!(username: 'example', email: 'test@localhost', password: 'test123456')
    user.confirm!
    user
  end

  let(:permission) { Permission.create!(name: 'use.test_app') }
  let(:group) { Group.create!(name: 'my_group', permissions: [permission]) }

  describe 'unauthenticated_user' do
    it 'forbids non-authenticated user' do
      get :create, params: { permission_name: 'use.test_app' }
      expect(response.status).to eq(401)
    end
  end

  describe 'authenticated_user' do
    context 'with session timeouts disabled (default)' do
      before do
        Setting.session_timeout_in = nil
      end

      it 'sets username and email as headers' do
        user.groups << group
        sign_in user
        get :create, params: { permission_name: 'use.test_app' }
        expect(response.status).to eq(200)
        expect(response.headers['EyeDP-Username']).to eq user.username
        expect(response.headers['EyeDP-Email']).to eq user.email
      end

      it 'allows authenticated role with group' do
        start = user.last_activity_at
        @request.env['devise.mapping'] = Devise.mappings[:user]
        user.groups << group
        sign_in user
        get :create, params: { permission_name: 'use.test_app' }
        expect(response.status).to eq(200)
        user.reload
        expect(user.last_activity_at).not_to eq(start)
      end

      it 'allows an authenticated, old user session' do
        start = user.last_activity_at
        @request.env['devise.mapping'] = Devise.mappings[:user]
        user.groups << group
        sign_in user
        warden.session('user')['last_request_at'] = 7
        # user.last_acccess = 1.day.ago
        get :create, params: { permission_name: 'use.test_app' }

        expect(response.status).to eq(200)
        user.reload
        expect(user.last_activity_at).not_to eq(start)
      end
    end

    context 'with session timeouts enabled' do
      before do
        Setting.session_timeout_in = 1.hour
      end

      it 'allows authenticated role with group' do
        start = user.last_activity_at
        @request.env['devise.mapping'] = Devise.mappings[:user]
        user.groups << group
        sign_in user
        get :create, params: { permission_name: 'use.test_app' }
        expect(response.status).to eq(200)
        user.reload
        expect(user.last_activity_at).not_to eq(start)
      end

      it 'forbids an authenticated, timed out user' do
        @request.env['devise.mapping'] = Devise.mappings[:user]
        user.groups << group
        sign_in user
        warden.session('user')['last_request_at'] = 7
        # user.last_acccess = 1.day.ago
        get :create, params: { permission_name: 'use.test_app' }

        expect(response.status).to eq(401)
      end

      it 'it updates last_request_at on use' do
        @request.env['devise.mapping'] = Devise.mappings[:user]
        user.groups << group
        sign_in user
        start = 5.minutes.ago.to_i
        warden.session('user')['last_request_at'] = start
        get :create, params: { permission_name: 'use.test_app' }
        expect(response.status).to eq(200)
        expect(warden.session('user')['last_request_at']).not_to eq(start)
        # Warden is apparently doing something super weird with deciding
        # to update or not the last_request_at field. The check above passes,
        # even though it matches this one perfectly. This test is to comfirm
        # that no regressions are introduced that cause timeouts to happen
        # while a user regularly hits the auth backend.
        warden.session('user')['last_request_at'] = start
        get :create, params: { permission_name: 'use.test_app' }
        expect(response.status).to eq(200)
        expect(warden.session('user')['last_request_at']).not_to eq(start)
      end
    end

    it 'forbids authenticated role without required two factor' do
      group.update({ requires_2fa: true })
      @request.env['devise.mapping'] = Devise.mappings[:user]
      user.groups << group
      sign_in user
      get :create, params: { permission_name: 'use.test_app' }
      expect(response.status).to eq(403)
    end

    it 'forbids authenticated role without group' do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      sign_in user
      get :create, params: { permission_name: 'use.test_app' }
      expect(response.status).to eq(403)
    end
  end

  describe 'with access tokens' do
    it 'allows access' do
      token = AccessToken.create!(user: user)

      user.groups << Group.create!(name: 'my_group', permissions: [permission], permit_token: true)
      request.headers['EyeDP-Authorize'] = token.token
      get :create, params: { permission_name: 'use.test_app' }
      expect(response.status).to eq(200)
      token.reload
      expect(token.last_used_at).not_to be_nil
    end

    it 'denies expired access' do
      token = AccessToken.create!(user: user, expires_at: 2.days.ago)

      user.groups << Group.create!(name: 'my_group', permissions: [permission], permit_token: true)
      request.headers['EyeDP-Authorize'] = token.token
      get :create, params: { permission_name: 'use.test_app' }
      expect(response.status).to eq(401)
      token.reload
      expect(token.last_used_at).to be_nil
    end

    it 'denies access without group access' do
      token = AccessToken.create!(user: user)

      user.groups << Group.create!(name: 'my_group', permissions: [permission], permit_token: false)
      request.headers['EyeDP-Authorize'] = token.token
      get :create, params: { permission_name: 'use.test_app' }
      expect(response.status).to eq(401)
      token.reload
      expect(token.last_used_at).to be_nil
    end
  end
end
