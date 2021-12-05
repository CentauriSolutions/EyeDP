# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ApplicationsController, type: :controller do
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
    Application.create!(
      name: 'https://test.example.com', redirect_uri: 'https://test.example.com'
    )
  end
  let(:custom_userdata_type) { CustomUserdataType.create(name: 'has_pets', custom_type: 'boolean') }

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
          post(:update, params: { id: app.id, application: { display_url: 'test.com' } })
          app.reload
          expect(app.display_url).to eq('test.com')
        end

        it 'can update the required groups' do
          expect(app.groups).to be_empty
          post(:update, params:
            { id: app.id, application:
              { group_ids: [group.id] } })
          app.reload
          expect(app.groups).to include group
          post(:update, params:
            { id: app.id, application: { display_url: app.display_url, group_ids: [] } })
          app.reload
          expect(app.groups).not_to include group
        end

        it 'can update custom attributes' do
          expect(app.custom_userdata_types).to be_empty
          post(:update, params:
            { id: app.id, application:
              { custom_userdata_type_ids: [custom_userdata_type.id] } })
          app.reload
          expect(app.custom_userdata_types).to include custom_userdata_type
          post(:update, params:
            { id: app.id, application: { display_url: app.display_url, custom_userdata_type_ids: [] } })
          app.reload
          expect(app.custom_userdata_types).not_to include custom_userdata_type
        end

        # Updating the secret can only be done via the renew_secret functionality
        it 'cannot edit the secret' do
          secret = app.secret
          post(:update, params: { id: app.id, application: { secret: 'fake secret' } })
          app.reload
          expect(app.secret).to eq(secret)
        end

        it 'can edit the UID' do
          post(:update, params: { id: app.id, application: { uid: 'new uid' } })
          app.reload
          expect(app.uid).to eq('new uid')
        end

        it 'can hide the app from the dashboard' do
          expect(app.show_on_dashboard).to be true
          post(:update, params: { id: app.id, application: { show_on_dashboard: '0' } })
          app.reload
          expect(app.show_on_dashboard).to be false
        end
      end

      context 'Secrets' do
        render_views

        it 'does not show the secret on show' do
          get(:show, params: { id: app.id })
          expect(response.body).to match(
            %r{<dt>secret</dt>\s+<dd>\s+\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*}
          )
          expect(response.body).not_to include(app.secret)
        end

        it 'does not show the secret on edit' do
          get(:edit, params: { id: app.id })
          expect(response.body).to include(
            '<input value="******************************" class="form-control" disabled="disabled" ' \
            'type="text" name="application[secret]" id="application_secret" />'
          )
          expect(response.body).not_to include(app.secret)
        end

        it 'shows the secret after renewing secret on show' do
          post(:renew_secret, params: { application_id: app.id })
          get(:show, params: { id: app.id })
          app.reload
          expect(response.body).to include(app.secret)
        end

        it 'shows the secret after renewing secret on edit' do
          post(:renew_secret, params: { application_id: app.id })
          get(:edit, params: { id: app.id })
          app.reload
          expect(response.body).to include(app.secret)
        end

        it 'shows the secret after create' do
          post(:create, params: { application: { name: 'test', redirect_uri: 'https://example.com' } })
          application = Application.first
          get(:show, params: { id: application.id })
          expect(response.body).to include(application.secret)
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
