# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SudoRails::ApplicationController, type: :controller do
  before(:all) do
    SudoRails.confirm_strategy = ->(_, password) { password == 'foo' }
    @target_path = '/'
  end

  before do
    Setting.sudo_enabled = true
  end

  after do
    Setting.sudo_enabled = false
  end

  it 'if strategy resolves, redirects to target path with a valid sudo session' do
    post :confirm, params: { password: 'foo', target_path: @target_path }

    expect(SudoRails.valid_sudo_session?(session[:sudo_session])).to eq(true)
    expect(response).to redirect_to @target_path
    expect(flash[:alert]).to be nil
  end

  it 'if strategy does not resolve, redirects to target with an invalid sudo session' do
    post :confirm, params: { password: 'bar', target_path: @target_path }

    expect(SudoRails.valid_sudo_session?(session[:sudo_session])).to eq(false)
    expect(response).to redirect_to @target_path
    expect(flash[:alert]).to eq I18n.t('sudo_rails.invalid_pass')
  end

  context 'when using two-factor authentication ' do
    before do
      sign_in(user)
    end
    let(:user) do
      user = User.new(username: 'example', email: 'test@localhost', password: 'test1234')
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

    context 'via TOTP' do
      it 'redirects to target path with a valid sudo session' do
        post(:confirm, params: { target_path: @target_path, user: { otp_attempt: user.current_otp } })
        expect(SudoRails.valid_sudo_session?(session[:sudo_session])).to eq(true)
        expect(response).to redirect_to @target_path
        expect(flash[:alert]).to be nil
      end
    end
    context 'via U2F device' do
      it 'redirects to target path with a valid sudo session' do
        token = setup_u2f(@controller)
        create_u2f_device(user, token[:key_handle], token[:public_key], token[:certificate])
        device_response = token[:device].sign_response(@controller.session[:user_u2f_challenge])
        post :confirm, params: { user: { device_response: device_response }, target_path: @target_path }

        expect(SudoRails.valid_sudo_session?(session[:sudo_session])).to eq(true)
        expect(response).to redirect_to @target_path
        expect(flash[:alert]).to be nil
        # authenticate_2fa_u2f(remember_me: '1', login: user.username, device_response: device_response)
        # expect(response.cookies['remember_user_token']).to be_nil
        # expect(subject.current_user).to eq user
      end
    end
  end
end
