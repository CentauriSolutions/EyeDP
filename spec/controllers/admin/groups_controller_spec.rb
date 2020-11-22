# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::GroupsController, type: :controller do
  let(:user) { User.create!(username: 'user', email: 'user@localhost', password: 'test1234') }
  let(:group) { Group.create!(name: 'administrators') }
  let(:permission) { Permission.create!(name: 'test permission') }
  let(:admin) do
    user = User.create!(username: 'admin', email: 'admin@localhost', password: 'test1234')
    user.groups << group
    user
  end

  describe 'Group' do
    context 'signed in admin' do
      before do
        sign_in(admin)
      end

      it 'Shows the index page' do
        get :index
        expect(response.status).to eq(200)
      end

      context 'Edit' do
        it 'can update a welcome email' do
          expect(group.welcome_email).to eq(nil)
          post(:update, params: { id: group.id, group: { welcome_email: 'Test welcome email' } })
          group.reload
          expect(group.welcome_email).to eq('Test welcome email')
        end

        it 'can enable a permission' do
          expect(group.permissions.first).to be_nil
          post(:update, params: { id: group.id, group: { permission_ids: [permission.id] } })
          group.reload
          expect(group.permissions.first).to eq(permission)
        end

        it 'can disable a permission' do
          group.permissions << permission
          group.save
          expect(group.permissions.first).to eq(permission)
          post(:update, params: { id: group.id, group: {name: 'administrators', permission_ids: [] } })
          group.reload
          expect(group.permissions.first).to be_nil
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
