# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
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

      context 'when using valid password' do
        let(:user) do
          user = User.create!(username: 'example', email: 'test@localhost', password: 'test123456')
          user.confirm!
          user
        end
        let(:user_params) { { login: user.username, password: user.password } }

        it 'authenticates user correctly' do
          post(:create, params: { user: user_params })

          expect(subject.current_user).to eq user
        end

        context 'with rendered wiews' do
          render_views

          it 'renders two factor screen' do
            user.update({ otp_required_for_login: true })
            user.fido_usf_devices.create!(
              name: 'test', key_handle: 'test', public_key: 'test', certificate: 'test',
              last_authenticated_at: Time.zone.now
            )
            expect { post(:create, params: { user: user_params }) }.not_to raise_error
            expect(response.status).to eq(200)
          end
        end

        it 'does not authenticate an expired user' do
          user.update!(expires_at: 10.minutes.ago)

          post(:create, params: { user: user_params })
          expect(flash[:alert])
            .to match(/account is expired/)
        end

        it 'does not authenticate an disabled user' do
          user.update!(disabled_at: 10.minutes.ago)

          post(:create, params: { user: user_params })
          expect(flash[:alert])
            .to match(/account is disabled/)
        end

        it 'redirects to a known application' do
          Application.create!(uid: 'test', internal: true, redirect_uri: 'https://example.com', name: 'test')
          post(:create, params: { user: user_params, redirect_to: 'https://example.com' })
          expect(subject.current_user).to eq user
          expect(response.status).to eq(302)
          expect(response.headers['Location']).to eq('https://example.com')
        end

        it 'redirects to a known SAML provider' do
          SamlServiceProvider.create!(
            issuer_or_entity_id: 'https://example.com',
            metadata_url: 'https://example.com/metadata', response_hosts: ['example.com']
          )
          post(:create, params: { user: user_params, redirect_to: 'https://example.com' })
          expect(subject.current_user).to eq user
          expect(response.status).to eq(302)
          expect(response.headers['Location']).to eq('https://example.com')
        end

        it 'does not redirect to a random URL' do
          post(:create, params: { user: user_params, redirect_to: 'https://wrong.com' })
          expect(subject.current_user).to eq user
          expect(response.status).to eq(302)
          expect(response.headers['Location']).to eq('http://test.host/')
        end

        it 'does not redirect to a partial match URL with OIDC' do
          post(:create, params: { user: user_params })
          expect(subject.current_user).to eq user
          expect(response.status).to eq(302)
          expect(response.headers['Location']).to eq('http://test.host/')
          Application.create!(uid: 'test', internal: true, redirect_uri: 'https://example.com', name: 'test')
          get(:new, params: { redirect_to: 'https://ex' })
          expect(response.headers['Location']).to eq('http://test.host/')
        end

        it 'does not redirect to a partial match URL with SAML' do
          post(:create, params: { user: user_params })
          expect(subject.current_user).to eq user
          expect(response.status).to eq(302)
          expect(response.headers['Location']).to eq('http://test.host/')
          SamlServiceProvider.create!(
            issuer_or_entity_id: 'https://example.com',
            metadata_url: 'https://example.com/metadata', response_hosts: ['example.com']
          )
          get(:new, params: { redirect_to: 'https://exam' })
          expect(response.headers['Location']).to eq('http://test.host/')
        end

        context 'with multiple emails' do
          let(:user) do
            user = User.create!(username: 'example', email: 'test@localhost', password: 'test123456')
            user.confirm!
            Email.create!(address: 'test2@localhost', user: user).confirm
            user
          end

          it 'allows login with the primary email' do
            post(:create, params: { user: { login: user.email, password: 'test123456' } })

            expect(subject.current_user).to eq user
          end

          it 'allows login with additional emails' do
            user
            post(:create, params: { user: { login: 'test2@localhost', password: 'test123456' } })
            expect(subject.current_user).to eq user
          end

          it 'requires additional emails to be confirmed for login' do
            Email.create!(address: 'test3@localhost', user: user)
            post(:create, params: { user: { login: 'test3@localhost', password: 'test123456' } })
            expect(subject.current_user).to be_nil
            expect(controller)
              .to set_flash.now[:alert].to(/Invalid Login or password/)
          end
        end
      end
    end

    context 'when using two-factor authentication via OTP' do
      let(:user) do
        user = User.new(username: 'example', email: 'test@localhost', password: 'test123456')
        user.otp_required_for_login = true
        user.otp_secret = User.generate_otp_secret(32)
        user.generate_otp_backup_codes!
        user.confirm!
        user.save!
        user
      end

      def authenticate_2fa(user_params, otp_user_id: user.id)
        post(:create, params: { user: user_params }, session: { otp_user_id: otp_user_id })
      end

      context 'remember_me field' do
        it 'sets a remember_user_token cookie when enabled' do
          allow(controller).to receive(:find_user).and_return(user)
          expect(controller).not_to receive(:remember_me)

          authenticate_2fa({ remember_me: '1', otp_attempt: user.current_otp })

          expect(response.cookies['remember_user_token']).to be_nil
        end

        it 'does nothing when disabled' do
          allow(controller).to receive(:find_user).and_return(user)
          expect(controller).not_to receive(:remember_me)

          authenticate_2fa({ remember_me: '0', otp_attempt: user.current_otp })

          expect(response.cookies['remember_user_token']).to be_nil
        end
      end

      it 'has a strict timeout on OTP attempts' do
        post(:create, params: { user: { remember_me: '0', otp_attempt: user.current_otp } },
session: { otp_user_id: user.id, otp_started: (Time.now.utc - 10.minutes).to_s })
        expect(flash.now[:alert]).to eq('It took too long to verify your authentication device. Please try again')
      end

      it 'locks a user after many incorrect OTP attempts' do
        expect(user.access_locked?).not_to be_truthy
        started_at = Time.now.utc.to_s
        11.times do
          post(:create, params: { user: { remember_me: '0', otp_attempt: 123_456 } },
session: { otp_user_id: user.id, otp_started: started_at })
        end
        # binding.pry
        user.reload
        expect(user.access_locked?).to be_truthy
      end

      it 'redirects to a known application' do
        allow(controller).to receive(:find_user).and_return(user)
        Application.create!(uid: 'test', internal: true, redirect_uri: 'https://example.com', name: 'test')
        post(:create,
             params: { user: { otp_attempt: user.current_otp }, redirect_to: 'https://example.com' },
             session: { otp_user_id: user.id })
        expect(subject.current_user).to eq user
        expect(response.status).to eq(302)
        expect(response.headers['Location']).to eq('https://example.com')
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
            user = User.new(username: 'example2', email: 'test2@localhost', password: 'test123456')
            user.otp_required_for_login = true
            user.otp_secret = User.generate_otp_secret(32)
            user.generate_otp_backup_codes!
            user.confirm!
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
        user = User.new(username: 'example', email: 'test@localhost', password: 'test123456')
        user.otp_required_for_login = true
        user.otp_secret = User.generate_otp_secret(32)
        user.generate_otp_backup_codes!
        user.confirm!
        user.save!
        user
      end

      def authenticate_2fa_u2f(user_params)
        post(:create, params: { user: user_params }, session: { otp_user_id: user.id })
      end

      def create_u2f_device(user, key_handle, public_key, certificate, attributes = {})
        attrib = {
          user: user,
          name: 'Unnamed 1',
          key_handle: key_handle,
          public_key: public_key,
          certificate: certificate,
          counter: 0,
          last_authenticated_at: Time.zone.now
        }.update(attributes)
        FidoUsf::FidoUsfDevice.create!(attrib)
      end

      def setup_u2f(controller)
        setup_u2f_with_appid(controller.u2f_app_id)
      end

      def setup_u2f_with_appid(app_id)
        device = U2F::FakeU2F.new(app_id)
        key_handle = U2F.urlsafe_encode64(device.key_handle_raw)
        certificate = Base64.strict_encode64(device.cert_raw)
        public_key = device.origin_public_key_raw
        { device: device, key_handle: key_handle, certificate: certificate, public_key: public_key }
      end

      context 'remember_me field' do
        it 'sets a remember_user_token cookie when enabled' do
          expect(controller).not_to receive(:remember_me)
          token = setup_u2f(@controller)
          create_u2f_device(user, token[:key_handle], token[:public_key], token[:certificate])
          device_response = token[:device].sign_response(@controller.session[:user_u2f_challenge])
          authenticate_2fa_u2f(remember_me: '1', login: user.username, device_response: device_response)
          expect(response.cookies['remember_user_token']).to be_nil
          expect(subject.current_user).to eq user
        end

        it 'does nothing when disabled' do
          allow(controller).to receive(:find_user).and_return(user)
          expect(controller).not_to receive(:remember_me)
          token = setup_u2f(@controller)
          create_u2f_device(user, token[:key_handle], token[:public_key], token[:certificate])
          device_response = token[:device].sign_response(@controller.session[:user_u2f_challenge])

          authenticate_2fa_u2f(remember_me: '0', login: user.username, device_response: device_response)

          expect(response.cookies['remember_user_token']).to be_nil
          expect(subject.current_user).to eq user
        end
      end

      it 'redirects to a known application' do
        allow(User).to receive(:u2f_authenticate).and_return(true)
        allow(controller).to receive(:find_user).and_return(user)
        Application.create!(uid: 'test', internal: true, redirect_uri: 'https://example.com', name: 'test')
        token = setup_u2f(@controller)
        create_u2f_device(user, token[:key_handle], token[:public_key], token[:certificate])
        device_response = token[:device].sign_response(@controller.session[:user_u2f_challenge])
        post(:create,
             params: { user: { login: user.username, device_response: device_response },
                redirect_to: 'https://example.com' },
             session: { otp_user_id: user.id })
        expect(subject.current_user).to eq user
        expect(response.status).to eq(302)
        expect(response.headers['Location']).to eq('https://example.com')
      end
    end
  end
end
