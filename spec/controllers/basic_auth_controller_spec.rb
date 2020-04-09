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
      @request.env['devise.mapping'] = Devise.mappings[:user]
      user.groups << group
      sign_in user
      get :create, params: { permission_name: 'use.test_app' }
      expect(response.status).to eq(200)
    end
    it 'forbids authenticated role without group' do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      sign_in user
      get :create, params: { permission_name: 'use.test_app' }
      expect(response.status).to eq(401)
    end
  end
end
