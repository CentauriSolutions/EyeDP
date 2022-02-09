# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  context 'Home page' do
    let(:user) do
      user = User.create!(username: 'example', email: 'test@localhost', password: 'test123456')
      user.confirm!
      user
    end
    before do
      sign_in(user)
    end

    context 'SAML apps' do
      let(:app) do
        SamlServiceProvider.create!(
          name: 'https://test.example.com', issuer_or_entity_id: 'example.com',
          metadata_url: 'https://test.example.com/metadata', response_hosts: ['example.com']
        )
      end

      before do
        app
      end

      it 'includes the app in the dashboard variables' do
        get :home
        expect(@controller.instance_variable_get(:@applications)).to match [app]
      end

      context 'with a restricted app' do
        let(:app) do
          a = SamlServiceProvider.create!(
            name: 'https://test.example.com', issuer_or_entity_id: 'example.com',
            metadata_url: 'https://test.example.com/metadata', response_hosts: ['example.com']
          )
          a.groups << Group.create!
          a
        end

        it 'does not include the app in the dashboard variables' do
          get :home
          expect(@controller.instance_variable_get(:@applications)).to be_empty
        end
      end

      context 'with a hidden app' do
        let(:app) do
          SamlServiceProvider.create!(
            name: 'https://test.example.com', issuer_or_entity_id: 'example.com',
            metadata_url: 'https://test.example.com/metadata', response_hosts: ['example.com'],
            show_on_dashboard: false
          )
        end

        it 'does not include the app in the dashboard variables' do
          get :home
          expect(@controller.instance_variable_get(:@applications)).to be_empty
        end
      end
    end

    context 'with an OIDC app' do
      let(:app) do
        Application.create!(
          uid: 'test',
          internal: true,
          redirect_uri: 'https://example.com',
          name: 'this is a fairly high entropy test string'
        )
      end

      before do
        app
      end

      it 'includes the app in the dashboard variables' do
        get :home
        expect(@controller.instance_variable_get(:@applications)).to match [app]
      end

      context 'with views' do
        render_views
        it 'escapes templated details' do
          app.name = 'alert("Hello, world!")'
          app.save
          get :home
          expect(response.body).not_to include('alert("Hello, world!")')
          expect(response.body).to include('alert(&quot;Hello, world!&quot;)')
        end
      end

      context 'with a restricted app' do
        let(:app) do
          a = Application.create!(
            uid: 'test',
            internal: true,
            redirect_uri: 'https://example.com',
            name: 'this is a fairly high entropy test string'
          )
          a.groups << Group.create!
          a
        end

        it 'does not include the app in the dashboard variables' do
          get :home
          expect(@controller.instance_variable_get(:@applications)).to be_empty
        end
      end

      context 'with a hidden app' do
        let(:app) do
          Application.create!(
            uid: 'test',
            internal: true,
            redirect_uri: 'https://example.com',
            name: 'this is a fairly high entropy test string',
            show_on_dashboard: false
          )
        end

        it 'does not include the app in the dashboard variables' do
          get :home
          expect(@controller.instance_variable_get(:@applications)).to be_empty
        end
      end
    end

    context 'with rendered views' do
      render_views

      it 'renders template' do
        Setting.dashboard_template = 'Hello, Rspec!'
        get :home
        expect(response.body).to include('Hello, Rspec!')
      end
    end
  end
end
