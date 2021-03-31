# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do
  include ActiveJob::TestHelper
  let(:user) { User.create!(username: 'user', email: 'user@localhost', password: 'test1234') }
  let(:admin_group) { Group.create!(name: 'administrators', admin: true) }
  let(:user_group) { Group.create!(name: 'users') }
  let(:admin) do
    user = User.create!(username: 'admin', email: 'admin@localhost', password: 'test1234')
    user.groups << admin_group
    user
  end

  let(:operator_group) { Group.create!(name: 'operators', operator: true) }
  let(:operator) do
    user = User.create!(username: 'operator', email: 'operator@localhost', password: 'test1234')
    user.groups << operator_group
    user
  end

  let(:manager_group) { Group.create!(name: 'managers', manager: true) }
  let(:manager) do
    user = User.create!(username: 'manager', email: 'manager@localhost', password: 'test1234')
    user.groups << manager_group
    user
  end

  describe 'User' do
    context 'signed in manager' do
      before do
        sign_in(manager)
      end

      it 'Shows the index page' do
        get :index
        expect(response.status).to eq(200)
      end

      it 'can add a user to a group' do
        expect(user.groups.pluck(:name)).to eq []
        post(:update, params: { id: user.id, user: { group_ids: [user_group.id] } })
        user.reload
        expect(user.groups.pluck(:name)).to eq %w[users]
      end

      it 'can remove a user from a group' do
        user.groups << user_group
        post(:update, params: { id: user.id, user: { name: user.name, group_ids: [] } })
        user.reload
        expect(user.groups).to eq []
      end

      it 'cannot add a user to an operator group' do
        post(:update, params: { id: user.id, user: { group_ids: [user_group.id, operator_group.id] } })
        user.reload
        expect(user.groups.pluck(:name)).to eq %w[users]
      end

      it 'cannot remove a user from an operator group' do
        user.groups << operator_group
        expect(user.groups.pluck(:name)).to eq %w[operators]
        post(:update, params: { id: user.id, user: { username: user.username, group_ids: [] } })
        user.reload
        expect(user.groups.pluck(:name)).to eq %w[operators]
      end

      it 'cannot add a user to an admin group' do
        expect(user.groups.pluck(:name)).to eq []
        post(:update, params: { id: user.id, user: { group_ids: [admin_group.id] } })
        user.reload
        expect(user.groups.pluck(:name)).to eq []
      end

      it 'cannot remove a user from an admin group' do
        expect(admin.groups.pluck(:name)).to eq %w[administrators]
        post(:update, params: { id: admin.id, user: { username: admin.username, group_ids: [] } })
        admin.reload
        expect(admin.groups.pluck(:name)).to eq %w[administrators]
      end

      it 'can update a user' do
        post(:update, params: { id: user.id, user: { username: 'testing-name' } })
        expect(response.status).to eq(302)
        user.reload
        expect(user.username).to eq('testing-name')
      end

      it 'cannot update an operator' do
        user.groups << operator_group
        post(:update, params: { id: user.id, user: { username: 'testing-name' } })
        expect(response.status).to eq(302)
        user.reload
        expect(user.username).to eq('user')
      end

      it 'cannot update an admin' do
        user.groups << admin_group
        post(:update, params: { id: user.id, user: { username: 'testing-name' } })
        expect(response.status).to eq(302)
        user.reload
        expect(user.username).to eq('user')
      end
    end

    context 'signed in operator' do
      before do
        sign_in(operator)
      end

      it 'Shows the index page' do
        expect { get :index }.to raise_error(ActionController::RoutingError)
      end
    end

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

        it "Can see a user's custom attributes" do
          CustomUserdataType.create(name: 'Has pets', custom_type: 'boolean')
          get(:show, params: { id: user.id })
          # The chewckbox below has a value of true, but is not checked, indicating that it is false
          expect(response.body).to include('id="custom_data_Has_pets" value="true" disabled="disabled"')
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
          post(:update, params: { id: user.id, user: { group_ids: [admin_group.id, user_group.id] } })
          user.reload
          expect(user.groups.pluck(:name).sort).to eq %w[administrators users]
        end

        it 'can remove a user from a group' do
          user.groups << user_group
          post(:update, params: { id: user.id, user: { group_ids: [admin_group.id] } })
          user.reload
          expect(user.groups.last.name).to eq 'administrators'
        end

        it "Can update a user's custom attributes" do
          CustomUserdataType.create(name: 'Has pets', custom_type: 'boolean')
          post :update_custom_attributes, params: { user_id: user.id, custom_data: { 'Has pets': true } }
          data = user.custom_userdata.first
          expect(data.name).to eq('Has pets')
          expect(data.value).to be true
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
