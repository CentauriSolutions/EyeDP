# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::DashboardController, type: :controller do
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

  describe 'Dashboard' do
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
      let(:app) do
        Application.create!(
          name: 'https://test.example.com', redirect_uri: 'https://test.example.com'
        )
      end

      before do
        sign_in(admin)
      end

      it 'Shows the dashboard' do
        get :index
        expect(response.status).to eq(200)
      end
      context 'with rendered views' do
        render_views
        context 'with sudo enabled' do
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

        it 'shows the current git hash' do
          EyedP::Application::GIT_SHA ||= 'Test SHA String'
          get :index
          expect(response.body).to include EyedP::Application::GIT_SHA[0..7]
        end
      end

      it 'includes recent logins' do
        Login.create(user: admin, service_provider: app)
        get :index
        expect(@controller.helpers.logins_by_app.map(&:first).map(&:id)).to include app.id
        expect(@controller.helpers.logins_by_user.map(&:first)).to include admin
      end

      it 'shows logins by app on apps dashboard' do
        login = Login.create(user: admin, service_provider: app)
        get :apps
        expect(@controller.instance_variable_get(:@logins)).to include(login)
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
