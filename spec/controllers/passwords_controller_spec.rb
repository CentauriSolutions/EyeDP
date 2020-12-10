# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Devise::PasswordsController do
  include DeviseHelpers

  before do
    set_devise_mapping(context: @request)
  end

  describe '#update' do
    render_views

    context 'updating the password' do
      subject do
        put :update, params: {
          user: {
            password: password,
            password_confirmation: password_confirmation,
            reset_password_token: reset_password_token
          }
        }
      end

      let(:password) { 'test1234' }
      let(:password_confirmation) { password }
      let(:reset_password_token) { user.send(:set_reset_password_token) }
      let(:user) { User.create!(username: 'example', email: 'test@localhost', password: 'test1234') }

      context 'password update is successful' do
        it 'updates the password-related flags' do
          subject
          user.reload

          expect(response).to redirect_to(new_user_session_path)
          expect(flash[:notice]).to include('password has been changed successfully')
        end
      end

      context 'password update is unsuccessful' do
        let(:password_confirmation) { 'not_the_same_as_password' }

        it 'does not update the password-related flags' do
          subject
          user.reload

          expect(response.body).to include('Password confirmation doesn&#39;t match Password')
        end
      end
    end
  end
end
