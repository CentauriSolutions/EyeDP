# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::SettingsController, type: :controller do
  let(:user) do
    user = User.create!(
      username: 'user', email: 'user@localhost',
      password: 'test123456', last_activity_at: 1.year.ago
    )
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

  describe 'User' do
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

      it 'cannot change dashboard_template' do
        Setting.dashboard_template = 'Default EyeDP Template'
        post(:update, params: { setting: { dashboard_template: 'Custom dashboard Template' } })
        expect(Setting.dashboard_template).to eq 'Default EyeDP Template'
      end

      it 'cannot change the registered_home_template' do
        Setting.registered_home_template = 'Default EyeDP Template'
        post(:update, params: { setting: { registered_home_template: 'Custom home Template' } })
        expect(Setting.registered_home_template).to eq 'Default EyeDP Template'
      end

      context 'with rendered views' do
        render_views
        it 'Does not show forbidden templates' do
          Setting.saml_certificate = File.read(Rails.root.join('spec/myCert.crt'))
          get :templates
          expect(response.body).not_to include('registered_home_template')
          expect(response.body).not_to include('dashboard_template')
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

      context 'with rendered views' do
        render_views
        it 'Shows the SAML certificate fingerprint' do
          Setting.saml_certificate = File.read(Rails.root.join('spec/myCert.crt'))
          get :saml
          expect(response.body).to include('4C:51:74:2D:C7:00:32:1A:87:79:AD:B8:1D:D8:8A:66:0C:FB:73:F3')
        end

        it 'cannot see the current SAML key' do
          Setting.saml_key = 'this is a test'
          get(:saml)
          expect(response.body).not_to include('this is a test')
          expect(response.body).to include(Digest::SHA1.hexdigest('this is a test'))
        end

        it 'cannot see the current oidc signing key' do
          Setting.oidc_signing_key = 'this is a test'
          get(:openid_connect)
          expect(response.body).not_to include('this is a test')
          expect(response.body).to include(Digest::SHA1.hexdigest('this is a test'))
        end
      end

      context 'Edit' do
        after do
          Setting.expire_after = nil
        end

        it "doesn't reset permanent email when changing HTML title" do
          Setting.permanent_email = true
          post(:update, params: { setting: { html_title_base: 'Custom EyeDP' } })
          expect(Setting.html_title_base).to eq 'Custom EyeDP'
          expect(Setting.permanent_email).to be true
        end

        it "doesn't reset expire_after when changing HTML title" do
          Setting.expire_after = 30.days
          post(:update, params: { setting: { html_title_base: 'Custom EyeDP' } })
          expect(Setting.html_title_base).to eq 'Custom EyeDP'
          expect(Setting.expire_after).to eq 30.days
        end

        it 'can update expire time' do
          expect(user.expired?).to be false
          post(:update, params: { setting: { expire_after: 30 } })
          expect(response.status).to eq(302)
          expect(user.expired?).to be true
          expect(Setting.expire_after).to eq 30.days
        end

        it 'can unset expire time' do
          Setting.expire_after = 30.days
          expect(user.expired?).to be true
          post(:update, params: { setting: { expire_after: '' } })
          expect(response.status).to eq(302)
          expect(user.expired?).to be false
          expect(Setting.expire_after).to eq nil
        end

        it 'can enable permenant email' do
          Setting.permanent_email = false
          post(:update, params: { setting: { permanent_email: 'true' } })
          expect(Setting.permanent_email).to be true
        end

        it 'can disable permenant email' do
          Setting.permanent_email = true
          post(:update, params: { setting: { permanent_email: 'false' } })
          expect(Setting.permanent_email).to be false
        end

        it 'can enable user registration' do
          Setting.registration_enabled = false
          post(:update, params: { setting: { registration_enabled: 'true' } })
          expect(Setting.registration_enabled).to be true
        end

        it 'can disable user registration' do
          Setting.registration_enabled = true
          post(:update, params: { setting: { registration_enabled: 'false' } })
          expect(Setting.registration_enabled).to be false
        end

        it 'can enable profiling' do
          Setting.profiler_enabled = false
          post(:update, params: { setting: { profiler_enabled: 'true' } })
          expect(Setting.profiler_enabled).to be true
        end

        it 'can disable profiling' do
          Setting.profiler_enabled = true
          post(:update, params: { setting: { profiler_enabled: 'false' } })
          expect(Setting.profiler_enabled).to be false
        end

        it 'can set password reset template' do
          post(:update, params: { setting: { admin_reset_email_template: 'Password was reset!' } })
          expect(Setting.admin_reset_email_template).to eq 'Password was reset!'
        end

        it 'can set user creation template' do
          post(:update, params: { setting: { admin_welcome_email_template: 'welcome to eyedp!' } })
          expect(Setting.admin_welcome_email_template).to eq 'welcome to eyedp!'
        end

        it 'can update HTML title' do
          post(:update, params: { setting: { html_title_base: 'Custom EyeDP' } })
          expect(Setting.html_title_base).to eq 'Custom EyeDP'
        end

        it 'can update the password reset token validity' do
          expect(Setting.devise_reset_password_within).to eq 7.days
          expect(Devise.reset_password_within).to eq 7.days
          post(:update, params: { setting: { devise_reset_password_within: '30' } })
          expect(Setting.devise_reset_password_within).to eq 30.days
          expect(Devise.reset_password_within).to eq 30.days
        end

        it 'can set the session timeout' do
          expect(Setting.session_timeout_in).to be nil
          expect(Devise.timeout_in).to be nil
          post(:update, params: { setting: { session_timeout_in: '24' } })
          expect(Setting.session_timeout_in).to eq 24.hours
          expect(Devise.timeout_in).to eq 24.hours
        end

        it 'can reset the session timeout to default' do
          Setting.session_timeout_in = 24.hours
          expect(Devise.timeout_in).to eq 24.hours
          post(:update, params: { setting: { session_timeout_in: '' } })
          expect(Setting.session_timeout_in).to be nil
          expect(Devise.timeout_in).to be nil
        end

        it 'can set the SAML timeout' do
          expect(Setting.saml_timeout).to be 0
          post(:update, params: { setting: { saml_timeout: '86400' } })
          expect(Setting.saml_timeout).to eq 86_400
        end

        it 'can update the oidc signing key' do
          expect(Setting.oidc_signing_key).to be nil
          post(:update, params: { setting: { oidc_signing_key: 'this is a test' } })
          expect(Setting.oidc_signing_key).to eq 'this is a test'
        end

        it 'can change dashboard_template' do
          Setting.dashboard_template = 'Default EyeDP Template'
          post(:update, params: { setting: { dashboard_template: 'Custom dashboard Template' } })
          expect(Setting.dashboard_template).to eq 'Custom dashboard Template'
        end

        it 'can change the registered_home_template' do
          Setting.registered_home_template = 'Default EyeDP Template'
          post(:update, params: { setting: { registered_home_template: 'Custom home Template' } })
          expect(Setting.registered_home_template).to eq 'Custom home Template'
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
