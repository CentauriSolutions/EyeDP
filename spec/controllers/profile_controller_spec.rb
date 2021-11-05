# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProfileController, type: :controller do
  let(:user) do
    user = User.create!(username: 'example', email: 'test@localhost', password: 'test1234')
    user.confirm!
    user
  end
  let(:app) do
    Application.create!(
      uid: 'test',
      internal: true,
      redirect_uri: 'https://example.com',
      name: 'this is a fairly high entropy test string'
    )
  end

  context 'User dashboard' do
    render_views
    before do
      sign_in(user)
    end

    it 'shows logins' do
      Login.create!(
        user: user,
        service_provider: app,
        auth_type: 'Existing Login'
      )
      get :show
      expect(response.body).to include('this is a fairly high entropy test string')
    end

    it 'notifies about group 2fa restriction' do
      user.groups << Group.create!(name: 'complex high entropoy test name', requires_2fa: true)
      get :show
      expect(response.body).to include('complex high entropoy test name')
      expect(response.body).to include('it requires two factor')
    end

    context 'with permenant email' do
      before do
        Setting.permanent_email = true
      end

      it 'can edit name' do
        get :show
        expect(response.body).to include('<input class="form-control" type="text" name="user[name]" id="user_name" />')
      end

      it 'cannot edit email' do
        get :show
        expect(response.body).to include(
          'disabled="disabled" class="form-control" type="email" value="test@localhost" ' \
          'name="user[email]" id="user_email" />'
        )
      end
    end

    context 'without permenant email' do
      before do
        Setting.permanent_email = false
      end

      it 'can edit name' do
        get :show
        expect(response.body).to include('<input class="form-control" type="text" name="user[name]" id="user_name" />')
      end

      it 'can edit email' do
        get :show
        expect(response.body).to include(
          'select name="user[email]" id="user_email"'
        )
      end
    end

    it 'blocks expired users' do
      user.update!(expires_at: 10.minutes.ago)

      get :show
      expect(flash[:alert])
        .to match(/account is expired/)
      expect(response.body).to include('redirected')
    end

    it 'updates user activity' do
      start = user.last_activity_at
      get :show
      user.reload
      expect(user.last_activity_at).not_to eq(start)
    end
  end
end
