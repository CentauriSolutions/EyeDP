# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Profile::AuthenticationDevicesController, type: :controller do # rubocop:disable Metrics/BlockLength
  let(:user) do
    User.create!(
      username: 'example',
      email: 'test@localhost',
      password: 'test1234'
    )
  end

  context 'index' do
    render_views
    before do
      sign_in(user)
    end

    it 'shows authentication devices' do
      user.consumed_timestep = 123
      user.otp_required_for_login = true
      user.save
      get :index
      expect(response.body).to include('TOTP')
    end

    it 'updates user activity' do
      start = user.last_activity_at
      get :index
      user.reload
      expect(user.last_activity_at).not_to eq(start)
    end
  end
end
