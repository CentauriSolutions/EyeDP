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
