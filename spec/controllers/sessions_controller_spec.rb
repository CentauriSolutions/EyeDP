# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SessionsController do
  include DeviseHelpers

  before do
    set_devise_mapping(context: @request)
  end

  describe '#create' do
    context 'when using standard authentications' do
      context 'invalid password' do
        it 'does not authenticate user' do
          post(:create, params: { user: { login: 'invalid', password: 'invalid' } })

          expect(controller)
            .to set_flash.now[:alert].to(/Invalid Login or password/)
        end
      end

      context 'when using valid password', :clean_gitlab_redis_shared_state do
        let(:user) { User.create!(username: 'example', email: 'test@localhost', password: 'test1234') }
        let(:user_params) { { login: user.username, password: user.password } }

        it 'authenticates user correctly' do
          post(:create, params: { user: user_params })

          expect(subject.current_user).to eq user
        end

        it 'does not authenticate an expired user' do
          user.update!(expires_at: 10.minutes.ago)

          post(:create, params: { user: user_params })
          expect(flash[:alert])
            .to match(/account is expired/)
        end
      end
    end

    context 'when using two-factor authentication via OTP' do
      let(:user) do
        user = User.new(username: 'example', email: 'test@localhost', password: 'test1234')
        user.otp_required_for_login = true
        user.otp_secret = User.generate_otp_secret(32)
        user.generate_otp_backup_codes!
        user.save!
        user
      end

      def authenticate_2fa(user_params, otp_user_id: user.id)
        post(:create, params: { user: user_params }, session: { otp_user_id: otp_user_id })
      end

      context 'remember_me field' do
        it 'sets a remember_user_token cookie when enabled' do
          allow(controller).to receive(:find_user).and_return(user)
          expect(controller)
            .to receive(:remember_me).with(user).and_call_original

          authenticate_2fa({ remember_me: '1', otp_attempt: user.current_otp })

          expect(response.cookies['remember_user_token']).to be_present
        end

        it 'does nothing when disabled' do
          allow(controller).to receive(:find_user).and_return(user)
          expect(controller).not_to receive(:remember_me)

          authenticate_2fa({ remember_me: '0', otp_attempt: user.current_otp })

          expect(response.cookies['remember_user_token']).to be_nil
        end
      end

      context 'when otp_user_id is stale' do
        render_views

        it 'favors login over otp_user_id when password is present and does not authenticate the user' do
          authenticate_2fa(
            { login: 'random_username', password: user.password },
            otp_user_id: user.id
          )

          expect(controller).to set_flash.now[:alert].to(/Invalid Login or password/)
        end
      end

      context 'when authenticating with login and OTP of another user' do
        context 'when another user has 2FA enabled' do
          let(:another_user) do
            user = User.new(username: 'example2', email: 'test2@localhost', password: 'test1234')
            user.otp_required_for_login = true
            user.otp_secret = User.generate_otp_secret(32)
            user.generate_otp_backup_codes!
            user.save!
            user
          end

          context 'when OTP is valid for another user' do
            it 'does not authenticate' do
              authenticate_2fa({ login: another_user.username,
                                 otp_attempt: another_user.current_otp })

              expect(subject.current_user).not_to eq another_user
            end
          end

          context 'when OTP is invalid for another user' do
            it 'does not authenticate' do
              authenticate_2fa({ login: another_user.username,
                                 otp_attempt: 'invalid' })

              expect(subject.current_user).not_to eq another_user
            end
          end

          context 'when authenticating with OTP' do
            context 'when OTP is valid' do
              it 'authenticates correctly' do
                authenticate_2fa({ otp_attempt: user.current_otp })

                expect(subject.current_user).to eq user
              end
            end

            context 'when OTP is invalid' do
              before do
                authenticate_2fa({ otp_attempt: 'invalid' })
              end

              it 'does not authenticate' do
                expect(subject.current_user).not_to eq user
              end

              it 'warns about invalid OTP code' do
                expect(controller).to set_flash.now[:alert]
                                               .to(/Invalid two-factor code/)
              end
            end
          end
        end
      end
    end

    context 'when using two-factor authentication via U2F device' do
      let(:user) do
        user = User.new(username: 'example', email: 'test@localhost', password: 'test1234')
        user.otp_required_for_login = true
        user.otp_secret = User.generate_otp_secret(32)
        user.generate_otp_backup_codes!
        user.save!
        user
      end

      def authenticate_2fa_u2f(user_params)
        post(:create, params: { user: user_params }, session: { otp_user_id: user.id })
      end

      context 'remember_me field' do
        it 'sets a remember_user_token cookie when enabled' do
          allow(User).to receive(:u2f_authenticate).and_return(true)
          allow(controller).to receive(:find_user).and_return(user)
          expect(controller)
            .to receive(:remember_me).with(user).and_call_original

          authenticate_2fa_u2f(remember_me: '1', login: user.username, device_response: '{}')

          expect(response.cookies['remember_user_token']).to be_present
        end

        it 'does nothing when disabled' do
          allow(User).to receive(:u2f_authenticate).and_return(true)
          allow(controller).to receive(:find_user).and_return(user)
          expect(controller).not_to receive(:remember_me)

          authenticate_2fa_u2f(remember_me: '0', login: user.username, device_response: '{}')

          expect(response.cookies['remember_user_token']).to be_nil
        end
      end
    end
  end
end
