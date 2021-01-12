# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do
  include ActiveJob::TestHelper
  let(:user) { User.create!(username: 'user', email: 'user@localhost', password: 'test1234') }
  let(:group) { Group.create!(name: 'administrators', admin: true) }
  let(:user_group) { Group.create!(name: 'users') }
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

      context 'index' do
        render_views

        it 'Shows the index page' do
          get :index
          expect(response.status).to eq(200)
        end

        it 'shows if a user has two factor enabled' do
          user.update({ otp_required_for_login: true })
          get :index
          expect(response.body).to match(/<td class="two_factor_enabled">\s+true/)
        end

        it 'shows if a user does not have two factor enabled' do
          user.update({ otp_required_for_login: false })
          get :index
          expect(response.body).to match(/<td class="two_factor_enabled">\s+false/)
        end
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

      context 'Show' do
        render_views

        it 'Can see if a user has two factor enabled' do
          user.update({ otp_required_for_login: true })
          get(:show, params: { id: user.id })
          expect(response.body).to match(%r{<dt>two_factor_enabled\?</dt>\s+<dd>\s+true})
        end

        it 'Can see if a user does not have two factor enabled' do
          user.update({ otp_required_for_login: false })
          get(:show, params: { id: user.id })
          expect(response.body).to match(%r{<dt>two_factor_enabled\?</dt>\s+<dd>\s+false})
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

        it 'can add a user to a group' do
          post(:update, params: { id: user.id, user: { group_ids: [group.id, user_group.id] } })
          user.reload
          expect(user.groups.pluck(:name)).to eq %w[administrators users]
        end

        it 'can remove a user from a group' do
          user.groups << user_group
          post(:update, params: { id: user.id, user: { group_ids: [group.id] } })
          user.reload
          expect(user.groups.last.name).to eq 'administrators'
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
