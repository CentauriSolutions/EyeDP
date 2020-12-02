# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BasicAuthController, type: :controller do
  let(:user) { User.create!(username: 'example', email: 'test@localhost', password: 'test1234') }

  describe 'unauthenticated_user' do
    it 'forbids non-authenticated user' do
      get :create, params: { permission_name: 'use.test_app' }
      expect(response.status).to eq(401)
    end
  end

  describe 'authenticated_user' do
    let(:permission) { Permission.create!(name: 'use.test_app') }
    let(:group) { Group.create!(name: 'my_group', permissions: [permission]) }

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

    describe 'Basic auth' do
      def http_login(user = 'example', password = 'test1234')
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(
          user, password
        )
      end

      it 'allows access with basic auth' do
        start = user.last_activity_at
        user.groups << group
        http_login
        get :create, params: { permission_name: 'use.test_app' }
        expect(response.status).to eq(200)
        user.reload
        expect(user.last_activity_at).not_to eq(start)
      end

      it 'blocks bad user username' do
        start = user.last_activity_at
        user.groups << group
        http_login('bad username', user.password)
        get :create, params: { permission_name: 'use.test_app' }
        expect(response.status).to eq(401)
        expect(user.last_activity_at).to eq(start)
      end

      it 'blocks bad user password' do
        start = user.last_activity_at
        user.groups << group
        http_login(user.username, 'not right password')
        get :create, params: { permission_name: 'use.test_app' }
        expect(response.status).to eq(401)
        expect(user.last_activity_at).to eq(start)
      end
    end
  end
end
