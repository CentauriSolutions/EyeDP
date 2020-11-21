# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do
  include ActiveJob::TestHelper
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

      context 'New' do
        it 'can create a user' do
          expect do
            perform_enqueued_jobs do
              post(:create, params: { user: { email: 'test@example.com', username: 'test' } })
              expect(response.status).to eq(302)
            end
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
      end

      context 'Edit' do
        it 'can expire a user' do
          expect(user.expired?).to be false
          post(:update, params: { id: user.id, user: { expires_at: 10.minutes.ago } })
          expect(response.status).to eq(302)
          user.reload
          expect(user.expired?).to be true
        end

        it 'can re-enable a timed-out User' do
          user.update!({ last_activity_at: 30.days.ago })
          Setting.expire_after = 15.days
          expect(user.expired?).to eq true
          post(:update, params: { id: user.id, user: { last_activity_at: nil } })
          user.reload
          expect(user.expired?).to eq false
        end

        it 'can reset a user passowrd' do
          expect(user.valid_password?('test1234')).to be true
          post(:reset_password, params: { user_id: user.id })
          expect(response.status).to eq(302)
          user.reload
          expect(user.valid_password?('test1234')).to be false
        end

        it 'can set a user password' do
          expect(user.valid_password?('test1234')).to be true
          post(:update, params: { id: user.id, user: { password: 'testing-it' } })
          expect(response.status).to eq(302)
          user.reload
          expect(user.valid_password?('test1234')).to be false
          expect(user.valid_password?('testing-it')).to be true
        end

        it 'can update a user without setting password' do
          post(:update, params: { id: user.id, user: { username: 'testing-name' } })
          expect(response.status).to eq(302)
          user.reload
          expect(user.username).to eq('testing-name')
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
