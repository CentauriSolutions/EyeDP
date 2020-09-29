# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do
  let(:user) { User.create!(username: 'user', email: 'user@localhost', password: 'test1234') }
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
        it 'can expire a user' do
          expect(user.expired?).to be false
          post(:update, params: { id: user.id, user: { expires_at: 10.minutes.ago } })
          expect(response.status).to eq(302)
          user.reload
          expect(user.expired?).to be true
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
