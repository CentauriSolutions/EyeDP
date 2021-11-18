# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OpenID Connect Flow', type: :request do
  before(:all) do
    Setting.oidc_signing_key = File.read(Rails.root.join('spec/key.pem'))
  end
  after(:all) do
    Setting.oidc_signing_key = nil
  end
  let(:user) do
    user = User.create!(username: 'example', email: 'test@localhost', password: 'test123456')
    user.confirm!
    user
  end
  let(:users_group) { Group.create!(name: 'users') }
  let(:application) do
    Application.create!(uid: 'test', internal: true, redirect_uri: 'https://example.com', name: 'test')
  end
  let(:params) do
    {
      response_type: 'code',
      client_id: application.uid,
      redirect_uri: application.redirect_uri,
      state: 'state'
    }
  end
  let(:access_grant) do
    Doorkeeper.config.access_grant_model.create(
      resource_owner_id: user.id,
      scopes: application.scopes,
      token: Doorkeeper::OAuth::Helpers::UniqueToken.generate,
      expires_in: 2.hours,
      application: application,
      redirect_uri: application.redirect_uri
    )
  end

  let(:access_token) do
    Doorkeeper.config.access_token_model.create(
      resource_owner_id: user.id,
      scopes: 'openid profile',
      application: application
    )
  end

  let(:id_token_claims) do
    {
      'sub' => Digest::SHA256.hexdigest("#{user.id}#{URI.parse(application.redirect_uri).host}")
    }
  end

  let(:user_info_claims) do
    {
      'name'           => 'example',
      'username'       => 'example',
      'email'          => 'test@localhost',
      'email_verified' => true,
      'groups'         => kind_of(Array)
    }
  end

  def request_access_token!
    sign_in user

    post '/oauth/token',
         params: {
           grant_type: 'authorization_code',
           code: access_grant.token,
           redirect_uri: application.redirect_uri,
           client_id: application.uid,
           client_secret: application.secret
         }
  end

  def request_user_info!
    get '/oauth/userinfo', params: {}, headers: { 'Authorization' => "Bearer #{access_token.token}" }
  end

  context 'Application with OpenID scope' do
    let(:application) do
      Application.create!(uid: 'test', internal: true, redirect_uri: 'https://example.com', name: 'test',
                          scopes: 'openid')
    end

    it 'token response includes an ID token' do
      request_access_token!
      json_response = JSON.parse(response.body)
      expect(json_response).to include 'id_token'
    end

    context 'UserInfo payload' do
      before do
        user.groups << users_group
        request_user_info!
      end

      it 'includes all user information and group memberships' do
        json_response = JSON.parse(response.body)
        expect(json_response).to match(id_token_claims.merge(user_info_claims))
        expect(json_response['groups']).to match([users_group.name])
      end

      context 'with a group restricted SP' do
        let(:other_group) { Group.create!(name: 'users2') }
        let(:application) do
          app = Application.create!(uid: 'test', internal: true, redirect_uri: 'https://example.com', name: 'test',
                                    scopes: 'openid')
          app.groups << other_group
          app
        end

        it "doesn't allow other group access" do
          json_response = JSON.parse(response.body)
          expect(json_response).to match(id_token_claims.merge(user_info_claims))
          expect(json_response['groups']).to match([users_group.name])
        end
      end
    end
  end
end
