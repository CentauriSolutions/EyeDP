# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::GroupsController, type: :controller do
  let(:group) { Group.create!(name: 'group') }
  let(:user) do
    u = User.create!(username: 'user', email: 'user@localhost', password: 'test1234')
    u.groups << group
    u
  end

  describe 'list groups' do
    context 'missing API key' do
      let(:api_key) { ApiKey.create }
      it 'lists users' do
        get :index
        expect(response.status).to eq(400)
      end

      context 'Edit' do
        it 'can not edit the description' do
          expect(group.description).to eq(nil)
          post(:update, params: { id: group.id, group: { description: 'Test description' } })
          expect(response.status).to eq(400)
          group.reload
          expect(group.description).to be nil
        end

        it 'can not update a welcome email' do
          expect(group.welcome_email).to eq(nil)
          post(:update, params: { id: group.id, group: { welcome_email: 'Test welcome email' } })
          expect(response.status).to eq(400)
          group.reload
          expect(group.welcome_email).to be nil
        end

        it 'can not require two factor' do
          expect(group.requires_2fa).to be false
          post(:update, params: { id: group.id, group: { requires_2fa: '1' } })
          expect(response.status).to eq(400)
          group.reload
          expect(group.requires_2fa).to be false
        end

        it 'can not not require two factor' do
          group.update(requires_2fa: true)
          expect(group.requires_2fa).to be true
          post(:update, params: { id: group.id, group: { requires_2fa: '0' } })
          expect(response.status).to eq(400)
          group.reload
          expect(group.requires_2fa).to be true
        end
      end

      it 'can not list users in a group' do
        get(:list_users, params: { group_id: group.id })
        expect(response.status).to eq(400)
      end

      it 'can not remove a user from a group' do
        expect(group.users).to eq [user]
        delete(:remove_user, params: { group_id: group.id, user_id: user.id })
        expect(response.status).to eq(400)
        group.reload
        expect(group.users).to eq [user]
      end

      it 'can not add a user to the group' do
        expect(group.users).to eq [user]
        user2 = User.create!(username: 'user2', email: 'user2@localhost', password: 'test1234')
        post(:add_user, params: { group_id: group.id, user_id: user2.id })
        expect(response.status).to eq(400)
        group.reload
        expect(group.users).to eq [user]
      end
    end

    context 'invalid API key' do
      let(:api_key) { ApiKey.create }
      it 'lists users' do
        get :index, params: { api_key: 'nope' }
        expect(response.status).to eq(403)
      end

      context 'Edit' do
        it 'can not edit the description' do
          expect(group.description).to eq(nil)
          post(:update, params: { api_key: 'nope', id: group.id, group: { description: 'Test description' } })
          expect(response.status).to eq(403)
          group.reload
          expect(group.description).to be nil
        end

        it 'can not update a welcome email' do
          expect(group.welcome_email).to eq(nil)
          post(:update, params: { api_key: 'nope', id: group.id, group: { welcome_email: 'Test welcome email' } })
          expect(response.status).to eq(403)
          group.reload
          expect(group.welcome_email).to be nil
        end

        it 'can not require two factor' do
          expect(group.requires_2fa).to be false
          post(:update, params: { api_key: 'nope', id: group.id, group: { requires_2fa: '1' } })
          expect(response.status).to eq(403)
          group.reload
          expect(group.requires_2fa).to be false
        end

        it 'can not not require two factor' do
          group.update(requires_2fa: true)
          expect(group.requires_2fa).to be true
          post(:update, params: { api_key: 'nope', id: group.id, group: { requires_2fa: '0' } })
          expect(response.status).to eq(403)
          group.reload
          expect(group.requires_2fa).to be true
        end
      end

      it 'can not list users in a group' do
        get(:list_users, params: { api_key: 'nope', group_id: group.id })
        expect(response.status).to eq(403)
      end

      it 'can not remove a user from a group' do
        expect(group.users).to eq [user]
        delete(:remove_user, params: { api_key: 'nope', group_id: group.id, user_id: user.id })
        expect(response.status).to eq(403)
        group.reload
        expect(group.users).to eq [user]
      end

      it 'can not add a user to the group' do
        expect(group.users).to eq [user]
        user2 = User.create!(username: 'user2', email: 'user2@localhost', password: 'test1234')
        post(:add_user, params: { api_key: 'nope', group_id: group.id, user_id: user2.id })
        expect(response.status).to eq(403)
        group.reload
        expect(group.users).to eq [user]
      end
    end

    context 'Valid API key without permission' do
      let(:api_key) { ApiKey.create }
      it 'lists users' do
        get :index, params: { api_key: api_key.key }
        expect(response.status).to eq(403)
      end

      context 'Edit' do
        it 'can not edit the description' do
          expect(group.description).to eq(nil)
          post(:update, params: { api_key: api_key.key, id: group.id, group: { description: 'Test description' } })
          expect(response.status).to eq(403)
          group.reload
          expect(group.description).to be nil
        end

        it 'can not update a welcome email' do
          expect(group.welcome_email).to eq(nil)
          post(:update, params: { api_key: api_key.key, id: group.id, group: { welcome_email: 'Test welcome email' } })
          expect(response.status).to eq(403)
          group.reload
          expect(group.welcome_email).to be nil
        end

        it 'can not require two factor' do
          expect(group.requires_2fa).to be false
          post(:update, params: { api_key: api_key.key, id: group.id, group: { requires_2fa: '1' } })
          expect(response.status).to eq(403)
          group.reload
          expect(group.requires_2fa).to be false
        end

        it 'can not not require two factor' do
          group.update(requires_2fa: true)
          expect(group.requires_2fa).to be true
          post(:update, params: { api_key: api_key.key, id: group.id, group: { requires_2fa: '0' } })
          expect(response.status).to eq(403)
          group.reload
          expect(group.requires_2fa).to be true
        end
      end

      it 'can not list users in a group' do
        get(:list_users, params: { api_key: api_key.key, group_id: group.id })
        expect(response.status).to eq(403)
      end

      it 'can not remove a user from a group' do
        expect(group.users).to eq [user]
        delete(:remove_user, params: { api_key: api_key.key, group_id: group.id, user_id: user.id })
        expect(response.status).to eq(403)
        group.reload
        expect(group.users).to eq [user]
      end

      it 'can not add a user to the group' do
        expect(group.users).to eq [user]
        user2 = User.create!(username: 'user2', email: 'user2@localhost', password: 'test1234')
        post(:add_user, params: { api_key: api_key.key, group_id: group.id, user_id: user2.id })
        expect(response.status).to eq(403)
        group.reload
        expect(group.users).to eq [user]
      end
    end

    context 'valid API key' do
      let(:api_key) { ApiKey.create(capabilities_mask: ApiKey::CAPABILITIES.values.sum) }
      it 'lists users' do
        get :index, params: { api_key: api_key.key }
        expect(response.status).to eq(200)
      end

      context 'Edit' do
        it 'can edit the description' do
          expect(group.description).to eq(nil)
          post(:update, params: { api_key: api_key.key, id: group.id, group: { description: 'Test description' } })
          group.reload
          expect(group.description).to eq('Test description')
        end

        it 'can update a welcome email' do
          expect(group.welcome_email).to eq(nil)
          post(:update, params: { api_key: api_key.key, id: group.id, group: { welcome_email: 'Test welcome email' } })
          group.reload
          expect(group.welcome_email).to eq('Test welcome email')
        end

        it 'can require two factor' do
          expect(group.requires_2fa).to be false
          post(:update, params: { api_key: api_key.key, id: group.id, group: { requires_2fa: '1' } })
          group.reload
          expect(group.requires_2fa).to be true
        end

        it 'can not require two factor' do
          group.update(requires_2fa: true)
          expect(group.requires_2fa).to be true
          post(:update, params: { api_key: api_key.key, id: group.id, group: { requires_2fa: '0' } })
          group.reload
          expect(group.requires_2fa).to be false
        end
        context 'can set admin' do
          it 'key with all permissions' do
            group.update(admin: true)
            expect(group.admin).to be true
            post(:update, params: { api_key: api_key.key, id: group.id, group: { admin: '0' } })
            group.reload
            expect(group.admin).to be false
          end
          it 'key without admin permission' do
            api_key.capabilities_mask -= 256
            api_key.save
            group.update(admin: true)
            expect(group.admin).to be true
            post(:update, params: { api_key: api_key.key, id: group.id, group: { admin: '0' } })
            group.reload
            expect(group.admin).to be true
          end
        end
      end

      it 'can list users in a group' do
        get(:list_users, params: { api_key: api_key.key, group_id: group.id })
        expect(JSON.parse(response.body)['result']).to eq []
      end

      it 'can remove a user from a group' do
        expect(group.users).to eq [user]
        delete(:remove_user, params: { api_key: api_key.key, group_id: group.id, user_id: user.id })
        group.reload
        expect(group.users).to eq []
      end

      it 'can add a user to the group' do
        expect(group.users).to eq [user]
        user2 = User.create!(username: 'user2', email: 'user2@localhost', password: 'test1234')
        post(:add_user, params: { api_key: api_key.key, group_id: group.id, user_id: user2.id })
        group.reload
        expect(group.users).to eq [user, user2]
      end
    end
  end
end
