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
      user = User.new(username: 'example', email: 'test@localhost', password: 'test123456')
      user.otp_required_for_login = true
      user.otp_secret = User.generate_otp_secret(32)
      user.generate_otp_backup_codes!
      user.confirm!
      user.save!
      user
    end

    context 'via TOTP' do
      it 'redirects to target path with a valid sudo session' do
        post(:confirm, params: { target_path: @target_path, user: { otp_attempt: user.current_otp } })
        expect(SudoRails.valid_sudo_session?(session[:sudo_session])).to eq(true)
        expect(response).to redirect_to @target_path
        expect(flash[:alert]).to be nil
      end
    end
  end
end
