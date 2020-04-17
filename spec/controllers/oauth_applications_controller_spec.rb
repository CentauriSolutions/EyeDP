# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OauthApplicationsController, type: :controller do
  let(:user) { User.create!(username: 'example', email: 'test@localhost', password: 'test1234') }
  let(:app) { Application.create!(uid: 'test', internal: true, redirect_uri: 'https://example.com', name: 'test' ) }
  let(:params) do
    {
      response_type: "code",
      client_id: app.uid,
      redirect_uri: app.redirect_uri,
      state: 'state'
    }
  end

  context "signed in user" do
    before do
      sign_in(user)
    end


    describe 'Existing Login' do
      it 'records the login'  do
        # @request.env['devise.mapping'] = Devise.mappings[:user]
        get :create, params: params
        expect(response.status).to eq(302)
        expect(Login.count).to eq 1
      end
    end

    describe 'New login' do
      it 'records the login'  do
        # @request.env['devise.mapping'] = Devise.mappings[:user]
        get :create, params: params
        expect(response.status).to eq(302)
        expect(Login.count).to eq 1
      end
    end
  end

  context "signed out user" do
    it 'returns 301 code and redirects to login' do
      get :new
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to eq('http://test.host/users/sign_in')

    end
  end
end
