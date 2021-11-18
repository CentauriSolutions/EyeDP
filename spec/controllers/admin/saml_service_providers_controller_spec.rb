# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::SamlServiceProvidersController, type: :controller do
  let(:user) do
    user = User.create!(username: 'user', email: 'user@localhost', password: 'test123456')
    user.confirm!
    user
  end
  let(:group) { Group.create!(name: 'administrators', admin: true) }
  let(:admin) do
    user = User.create!(username: 'admin', email: 'admin@localhost', password: 'test123456')
    user.groups << group
    user.confirm!
    user
  end
  let(:app) do
    SamlServiceProvider.create!(
      name: 'https://test.example.com', issuer_or_entity_id: 'example.com',
      metadata_url: 'https://test.example.com/metadata', response_hosts: ['example.com']
    )
  end

  describe 'Application' do
    context 'signed in manager' do
      let(:manager_group) { Group.create!(name: 'managers', manager: true) }
      let(:manager) do
        user = User.create!(username: 'manager', email: 'manager@localhost', password: 'test123456')
        user.groups << manager_group
        user.confirm!
        user
      end

      before do
        sign_in(manager)
      end

      it 'Shows the index page' do
        expect { get :index }.to raise_error(ActionController::RoutingError)
      end
    end

    context 'signed in operator' do
      let(:operator_group) { Group.create!(name: 'operators', operator: true) }
      let(:operator) do
        user = User.create!(username: 'operator', email: 'operator@localhost', password: 'test123456')
        user.groups << operator_group
        user.confirm!
        user
      end

      before do
        sign_in(operator)
      end

      it 'Shows the index page' do
        get :index
        expect(response.status).to eq(200)
      end

      context 'with sudo enabled' do
        render_views
        before do
          Setting.sudo_enabled = true
          @controller.reset_sudo_session!
        end
        after do
          Setting.sudo_enabled = false
        end
        it 'Asks for password confirmation' do
          get :index
          expect(response.status).to eq(200)
          expect(response.body).to include 'Confirm password to continue'
        end

        it 'Works with a sudo session' do
          @controller.extend_sudo_session!
          get :index
          expect(response.status).to eq(200)
          expect(response.body).not_to include 'Confirm password to continue'
        end
      end
    end

    context 'signed in admin' do
      before do
        sign_in(admin)
      end

      it 'Shows the index page' do
        get :index
        expect(response.status).to eq(200)
      end

      context 'with sudo enabled' do
        render_views
        before do
          Setting.sudo_enabled = true
          @controller.reset_sudo_session!
        end
        after do
          Setting.sudo_enabled = false
        end
        it 'Asks for password confirmation' do
          get :index
          expect(response.status).to eq(200)
          expect(response.body).to include 'Confirm password to continue'
        end

        it 'Works with a sudo session' do
          @controller.extend_sudo_session!
          get :index
          expect(response.status).to eq(200)
          expect(response.body).not_to include 'Confirm password to continue'
        end
      end

      context 'Edit' do
        it 'can update the display_url' do
          expect(app.display_url).to be nil
          post(:update, params: { id: app.id, saml_service_provider: { display_url: 'test.com' } })
          app.reload
          expect(app.display_url).to eq('test.com')
        end

        it 'can update the required groups' do
          expect(app.groups).to be_empty
          post(:update, params:
            { id: app.id, saml_service_provider:
              { group_ids: [group.id] } })
          app.reload
          expect(app.groups).to include group
          post(:update, params:
            { id: app.id, saml_service_provider: { name: app.name, group_ids: [] } })
          app.reload
          expect(app.groups).not_to include group
        end
      end
    end

    context 'signed in user' do
      before do
        sign_in(user)
      end
      it 'returns 404 code' do
        expect { get :index }.to raise_error(ActionController::RoutingError)
      end
    end

    context 'signed out user' do
      it 'returns 404 code' do
        expect { get :index }.to raise_error(ActionController::RoutingError)
      end
    end
  end
end
