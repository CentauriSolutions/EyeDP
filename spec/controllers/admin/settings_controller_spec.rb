# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::SettingsController, type: :controller do
  let(:user) do
    User.create!(
      username: 'user', email: 'user@localhost',
      password: 'test1234', last_activity_at: 1.year.ago
    )
  end
  let(:group) { Group.create!(name: 'administrators') }
  let(:admin) do
    user = User.create!(username: 'admin', email: 'admin@localhost', password: 'test1234')
    user.groups << group
    user
  end

  describe 'User' do
    context 'signed in admin' do
      before do
        sign_in(admin)
      end

      it 'Shows the index page' do
        get :index
        expect(response.status).to eq(200)
      end

      context 'with rendered views' do
        render_views
        it 'Shows the SAML certificate fingerprint' do
          Setting.saml_certificate = File.read('myCert.crt')
          get :saml
          expect(response.body).to include('4C:51:74:2D:C7:00:32:1A:87:79:AD:B8:1D:D8:8A:66:0C:FB:73:F3')
        end
      end

      context 'Edit' do
        after do
          Setting.expire_after = nil
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

        it 'can enable permenant usernames' do
          Setting.permemant_username = false
          post(:update, params: { setting: { permemant_username: '' } })
          expect(Setting.permemant_username).to be true
        end

        it 'can disable permenant usernames' do
          Setting.permemant_username = true
          post(:update, params: { setting: {} })
          expect(Setting.permemant_username).to be false
        end

        it 'can enable user registration' do
          Setting.registration_enabled = false
          post(:update, params: { setting: { registration_enabled: '' } })
          expect(Setting.registration_enabled).to be true
        end

        it 'can disable user registration' do
          Setting.registration_enabled = true
          post(:update, params: { setting: {} })
          expect(Setting.registration_enabled).to be false
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
