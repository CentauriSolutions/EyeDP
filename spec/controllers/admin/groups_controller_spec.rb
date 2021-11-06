# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::GroupsController, type: :controller do
  let(:user) do
    user = User.create!(username: 'user', email: 'user@localhost', password: 'test1234')
    user.confirm!
    user
  end
  let(:group) { Group.create!(name: 'administrators', admin: true) }
  let(:users_group) { Group.create!(name: 'usesr') }
  let(:permission) { Permission.create!(name: 'test permission') }
  let(:admin) do
    user = User.create!(username: 'admin', email: 'admin@localhost', password: 'test1234')
    user.groups << group
    user.confirm!
    user
  end

  describe 'Group' do
    context 'signed in manager' do
      let(:manager_group) { Group.create!(name: 'managers', manager: true) }
      let(:manager) do
        user = User.create!(username: 'manager', email: 'manager@localhost', password: 'test1234')
        user.groups << manager_group
        user.confirm!
        user
      end

      before do
        sign_in(manager)
      end

      it 'Shows the index page' do
        get :index
        expect(response.status).to eq(200)
      end

      context 'with sudo enabled' do
        render_views
        before do
          Setting.sudo_enabled = true
          @controller.reset_sudo_session!
        end
        after do
          Setting.sudo_enabled = false
        end
        it 'Asks for password confirmation' do
          get :index
          expect(response.status).to eq(200)
          expect(response.body).to include 'Confirm password to continue'
        end

        it 'Works with a sudo session' do
          @controller.extend_sudo_session!
          get :index
          expect(response.status).to eq(200)
          expect(response.body).not_to include 'Confirm password to continue'
        end
      end
    end

    context 'signed in operator' do
      let(:operator_group) { Group.create!(name: 'operators', operator: true) }
      let(:operator) do
        user = User.create!(username: 'operator', email: 'operator@localhost', password: 'test1234')
        user.groups << operator_group
        user.confirm!
        user
      end

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

      it 'Shows the index page' do
        get :index
        expect(response.status).to eq(200)
      end

      context 'with sudo enabled' do
        render_views
        before do
          Setting.sudo_enabled = true
          @controller.reset_sudo_session!
        end
        after do
          Setting.sudo_enabled = false
        end
        it 'Asks for password confirmation' do
          get :index
          expect(response.status).to eq(200)
          expect(response.body).to include 'Confirm password to continue'
        end

        it 'Works with a sudo session' do
          @controller.extend_sudo_session!
          get :index
          expect(response.status).to eq(200)
          expect(response.body).not_to include 'Confirm password to continue'
        end
      end

      context 'Edit' do
        it 'can edit the description' do
          expect(group.description).to eq(nil)
          post(:update, params: { id: group.id, group: { description: 'Test description' } })
          group.reload
          expect(group.description).to eq('Test description')
        end

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
          post(:update, params: { id: group.id, group: { name: 'administrators', permission_ids: [] } })
          group.reload
          expect(group.permissions.first).to be_nil
        end

        it 'can require two factor' do
          expect(users_group.requires_2fa).to be false
          post(:update, params: { id: users_group.id, group: { requires_2fa: '1' } })
          users_group.reload
          expect(users_group.requires_2fa).to be true
        end

        it 'can not require two factor' do
          users_group.update(requires_2fa: true)
          expect(users_group.requires_2fa).to be true
          post(:update, params: { id: users_group.id, group: { requires_2fa: '0' } })
          users_group.reload
          expect(users_group.requires_2fa).to be false
        end

        context 'Show' do
          render_views
          it "Can see a group's custom attributes" do
            CustomGroupDataType.create(name: 'alias', custom_type: 'string')
            get(:show, params: { id: group.id })
            # The chewckbox below has a value of true, but is not checked, indicating that it is false
            expect(response.body).to match(/id="custom_data_alias".+disabled="disabled"/)
          end
        end

        context 'update' do
          it "Can update a group's custom attributes" do
            CustomGroupDataType.create(name: 'alias', custom_type: 'string')
            post :update, params: { id: group.id, group: { name: group.name }, custom_data: { 'alias': 'ahoy' } }
            data = group.custom_groupdata.first
            expect(data.name).to eq('alias')
            expect(data.value).to eq('ahoy')
          end
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
