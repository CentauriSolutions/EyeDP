# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do
  include ActiveJob::TestHelper
  let(:user) do
    user = User.new(username: 'user', email: 'user@localhost', password: 'test123456')
    user.emails[0].confirmed_at = Time.now.utc
    user.save!
    user
  end
  let(:admin_group) { Group.create!(name: 'administrators', admin: true) }
  let(:user_group) { Group.create!(name: 'users') }
  let(:admin) do
    user = User.create!(username: 'admin', email: 'admin@localhost', password: 'test123456')
    user.groups << admin_group
    user.confirm!
    user
  end

  let(:operator_group) { Group.create!(name: 'operators', operator: true) }
  let(:operator) do
    user = User.create!(username: 'operator', email: 'operator@localhost', password: 'test123456')
    user.groups << operator_group
    user.confirm!
    user
  end

  let(:manager_group) { Group.create!(name: 'managers', manager: true) }
  let(:manager) do
    user = User.create!(username: 'manager', email: 'manager@localhost', password: 'test123456')
    user.groups << manager_group
    user.confirm!
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

      it 'can search for users by email' do
        user
        get :index, params: { filter_by: 'email', filter: user.email }
        expect(response.status).to eq(200)
        expect(@controller.instance_variable_get(:@models)).to include user
      end

      it 'can search for users by username' do
        user
        get :index, params: { filter_by: 'username', filter: user.username }
        expect(response.status).to eq(200)
        expect(@controller.instance_variable_get(:@models)).to include user
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

      it 'can add a user to a group' do
        expect(user.groups.pluck(:name)).to eq []
        post(:update, params: { id: user.id, user: { group_ids: [user_group.id] } })
        user.reload
        expect(user.groups.pluck(:name)).to eq %w[users]
      end

      it 'can remove a user from a group' do
        user.groups << user_group
        post(:update, params: { id: user.id, user: { name: user.name, group_ids: [''] } })
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
        post(:update, params: { id: user.id, user: { username: user.username, group_ids: [''] } })
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
        post(:update, params: { id: admin.id, user: { username: admin.username, group_ids: [''] } })
        admin.reload
        expect(admin.groups.pluck(:name)).to eq %w[administrators]
      end

      it 'can create a user' do
        expect(User.joins(:emails).where(emails: { address: 'testing@localhost' }).count).to eq 0
        post(:create,
             params: { send_welcome_email: true, user: { email: 'testing@localhost', username: 'testing-name' } })
        expect(response.status).to eq(302)
        expect(User.joins(:emails).where(emails: { address: 'testing@localhost' }).count).to eq 1
      end

      it 'can create a user with additional emails' do
        expect do
          perform_enqueued_jobs do
            post(:create, params: {
                   send_welcome_email: true,
              user: { email: 'test@example.com', email_addresses: ['test2@example.com'], username: 'test' }
                 })
            expect(response.status).to eq(302)
            expect(User.find_by(username: 'test').emails.count).to eq 2
          end
        end.to change { ActionMailer::Base.deliveries.count }.by(2)
      end

      context 'duplicate' do
        render_views

        it 'can see errors' do
          User.create!(username: 'test', email: 'testing@localhost')
          expect(User.joins(:emails).where(emails: { address: 'testing@localhost' }).count).to eq 1
          post(:create,
               params: { send_welcome_email: true, user: { email: 'testing@localhost', username: 'testing-name' } })
          expect(response.status).to eq(200)
          expect(response.body).to include('Address has already been taken')
          expect(User.joins(:emails).where(emails: { address: 'testing@localhost' }).count).to eq 1
        end
      end

      it 'can create a user and retrieve reset link' do
        expect do
          perform_enqueued_jobs do
            expect(User.joins(:emails).where(emails: { address: 'testing@localhost' }).count).to eq 0
            post(:create, params: { user: { email: 'testing@localhost', username: 'testing-name' } })
            expect(response.status).to eq(302)
            expect(User.joins(:emails).where(emails: { address: 'testing@localhost' }).count).to eq 1
          end
        end.to change { ActionMailer::Base.deliveries.count }.by(0)
      end

      it 'can update a user' do
        post(:update, params: { id: user.id, user: { username: 'testing-name' } })
        expect(response.status).to eq(302)
        user.reload
        expect(user.username).to eq('testing-name')
      end

      it 'can resend the welcome email' do
        expect do
          perform_enqueued_jobs do
            post(:resend_welcome_email, params: { user_id: user.id })
            expect(response.status).to eq(302)
          end
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
        expect(flash[:notice]).to match('Welcome email will be sent.')
      end

      it 'can delete a user' do
        delete(:destroy, params: { id: user.id })
        expect(response.status).to eq(302)
        expect(User.where(username: user.username).count).to eq 0
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

      it 'cannot disable 2fa for an operator' do
        user.groups << operator_group
        user.update!({ otp_required_for_login: true })
        post(:disable_two_factor, params: { user_id: user.id })
        expect(response.status).to eq(302)
        user.reload
        expect(user.otp_required_for_login).to be true
      end

      it 'cannot disable 2fa for an admin' do
        user.groups << admin_group
        user.update!({ otp_required_for_login: true })
        post(:disable_two_factor, params: { user_id: user.id })
        expect(response.status).to eq(302)
        user.reload
        expect(user.otp_required_for_login).to be true
      end

      context 'edit' do
        render_views

        it 'does not show admin groups' do
          admin_group
          get :edit, params: { id: user.id }
          expect(response.status).to eq(200)
          expect(response.body).not_to include(%(type="checkbox" value="#{admin_group.id}" name="user[group_ids][]"))
          expect(response.body).to include(%(type="checkbox" value="#{manager_group.id}" name="user[group_ids][]"))
        end

        it "shows a user's custom attributes" do
          t = CustomUserdataType.create(name: 'Has pets', custom_type: 'boolean')
          manager.custom_userdata << CustomUserdatum.create(custom_userdata_type: t, value: true)

          # get self
          get(:edit, params: { id: manager.id })
          # The checkbox below has a value of true, and is checked
          expect(response.body).to include('id="custom_data_Has_pets" value="true"')
          # get other
          get(:edit, params: { id: user.id })
          # The hiddn field below has a value of false, allowing us to set an empty checkbox
          expect(response.body).to include(
            'type="hidden" name="custom_data[Has pets]" id="custom_data_Has_pets" value="false"'
          )
        end
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

        context 'with sudo enabled' do
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

        it 'shows if a user has two factor enabled' do
          user.update({ otp_required_for_login: true })
          get :index
          expect(response.body).to match(/<td class="two_factor_enabled">\s+<i class="fa fa-check/)
        end

        it 'shows if a user does not have two factor enabled' do
          user.update({ otp_required_for_login: false })
          get :index
          expect(response.body).to match(/<td class="two_factor_enabled">\s+<i class="fa fa-times/)
        end
      end

      context 'New' do
        it 'can create a user' do
          expect do
            perform_enqueued_jobs do
              post(:create, params: { send_welcome_email: true, user: { email: 'test@example.com', username: 'test' } })
              expect(response.status).to eq(302)
            end
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        it 'can create a user with additional emails' do
          expect do
            perform_enqueued_jobs do
              post(:create, params: {
                     send_welcome_email: true,
                user: { email: 'test@example.com', email_addresses: ['test2@example.com'], username: 'test' }
                   })
              expect(response.status).to eq(302)
              expect(User.find_by(username: 'test').emails.count).to eq 2
            end
          end.to change { ActionMailer::Base.deliveries.count }.by(2)
        end

        it 'can create a user with additional emails and empty entries' do
          expect do
            perform_enqueued_jobs do
              post(:create, params: {
                     send_welcome_email: true,
                user: { email: 'test@example.com', email_addresses: ['', 'test2@example.com'], username: 'test' }
                   })
              expect(response.status).to eq(302)
              expect(User.find_by(username: 'test').emails.count).to eq 2
            end
          end.to change { ActionMailer::Base.deliveries.count }.by(2)
        end

        context 'duplicate' do
          render_views

          it 'can see errors' do
            User.create!(username: 'test', email: 'testing@localhost')
            expect(User.joins(:emails).where(emails: { address: 'testing@localhost' }).count).to eq 1
            post(:create,
                 params: { send_welcome_email: true, user: { email: 'testing@localhost', username: 'testing-name' } })
            expect(response.status).to eq(200)
            expect(response.body).to include('Address has already been taken')
            expect(User.joins(:emails).where(emails: { address: 'testing@localhost' }).count).to eq 1
          end
        end

        it 'can create a user and retrieve reset link' do
          expect do
            perform_enqueued_jobs do
              expect(User.joins(:emails).where(emails: { address: 'testing@localhost' }).count).to eq 0
              post(:create, params: { user: { email: 'testing@localhost', username: 'testing-name' } })
              expect(response.status).to eq(302)
              expect(User.joins(:emails).where(emails: { address: 'testing@localhost' }).count).to eq 1
            end
          end.to change { ActionMailer::Base.deliveries.count }.by(0)
        end
      end

      context 'Show' do
        render_views

        it 'can reset a password with multiple emails' do
          Email.create(user: user, address: 'user2@localhost', confirmed_at: Time.now.utc)
          expect do
            perform_enqueued_jobs do
              post(:reset_password, params: { user_id: user.id })
              expect(response.status).to eq(302)
            end
          end.to change { ActionMailer::Base.deliveries.count }.by(2)
          expect(flash[:notice]).to match('Password reset was processed')
        end

        it 'only sends a reset link to confirmed emails' do
          Email.create(user: user, address: 'user2@localhost', confirmed_at: Time.now.utc)
          Email.create(user: user, address: 'user3@localhost')
          expect do
            perform_enqueued_jobs do
              post(:reset_password, params: { user_id: user.id })
              expect(response.status).to eq(302)
            end
          end.to change { ActionMailer::Base.deliveries.count }.by(2)
          expect(flash[:notice]).to match('Password reset was processed')
        end

        it 'can resend the welcome email' do
          expect do
            perform_enqueued_jobs do
              post(:resend_welcome_email, params: { user_id: user.id })
              expect(response.status).to eq(302)
            end
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
          expect(flash[:notice]).to match('Welcome email will be sent.')
        end

        it 'can send a welcome email with multiple emails' do
          Email.create(user: user, address: 'user2@localhost', confirmed_at: Time.now.utc)
          expect do
            perform_enqueued_jobs do
              post(:resend_welcome_email, params: { user_id: user.id })
              expect(response.status).to eq(302)
            end
          end.to change { ActionMailer::Base.deliveries.count }.by(2)
          expect(flash[:notice]).to match('Welcome email will be sent.')
        end

        it 'only sends a welcome email to confirmed emails' do
          Email.create(user: user, address: 'user2@localhost', confirmed_at: Time.now.utc)
          Email.create(user: user, address: 'user3@localhost')
          expect do
            perform_enqueued_jobs do
              post(:resend_welcome_email, params: { user_id: user.id })
              expect(response.status).to eq(302)
            end
          end.to change { ActionMailer::Base.deliveries.count }.by(2)
          expect(flash[:notice]).to match('Welcome email will be sent.')
        end

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
        context 'with views' do
          render_views

          it 'shows admin groups' do
            manager_group
            get :edit, params: { id: user.id }
            expect(response.status).to eq(200)
            expect(response.body).to include(%(type="checkbox" value="#{admin_group.id}" name="user[group_ids][]"))
            expect(response.body).to include(%(type="checkbox" value="#{manager_group.id}" name="user[group_ids][]"))
          end

          it "shows a user's custom attributes" do
            t = CustomUserdataType.create(name: 'Has pets', custom_type: 'boolean')
            admin.custom_userdata << CustomUserdatum.create(custom_userdata_type: t, value: true)

            # get self
            get(:edit, params: { id: admin.id })
            # The checkbox below has a value of true, and is checked
            expect(response.body).to include('id="custom_data_Has_pets" value="true"')
            # get other
            get(:edit, params: { id: user.id })
            # The hiddn field below has a value of false, allowing us to set an empty checkbox
            expect(response.body).to include(
              'type="hidden" name="custom_data[Has pets]" id="custom_data_Has_pets" value="false"'
            )
          end
        end
        it 'can expire a user' do
          expect(user.expired?).to be false
          post(:update, params: { id: user.id, user: { expires_at: 10.minutes.ago } })
          expect(response.status).to eq(302)
          user.reload
          expect(user.expired?).to be true
        end

        it 'expiring a user does not change their groups' do
          expect(user.expired?).to be false
          user.groups << user_group
          post(:update, params: { id: user.id, user: { expires_at: 10.minutes.ago } })
          expect(response.status).to eq(302)
          user.reload
          expect(user.expired?).to be true
          expect(user.groups).to include(user_group)
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
          expect(user.valid_password?('test123456')).to be true
          post(:reset_password, params: { user_id: user.id })
          expect(response.status).to eq(302)
          user.reload
          expect(user.valid_password?('test123456')).to be false
        end

        it 'can set a user password' do
          expect(user.valid_password?('test123456')).to be true
          post(:update, params: { id: user.id, user: { password: 'testing-it' } })
          expect(response.status).to eq(302)
          user.reload
          expect(user.valid_password?('test123456')).to be false
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
          post :update, params: {
            id: user.id,
            user: { username: user.username },
            custom_data: { 'Has pets': true }
          }
          data = user.custom_userdata.first
          expect(data.name).to eq('Has pets')
          expect(data.value).to be true
        end

        it 'can disable 2fa for a manager' do
          user.groups << manager_group
          user.update!({ otp_required_for_login: true })
          post(:disable_two_factor, params: { user_id: user.id })
          expect(response.status).to eq(302)
          user.reload
          expect(user.otp_required_for_login).to be false
        end

        it 'can disable 2fa for an operator' do
          user.groups << operator_group
          user.update!({ otp_required_for_login: true })
          post(:disable_two_factor, params: { user_id: user.id })
          expect(response.status).to eq(302)
          user.reload
          expect(user.otp_required_for_login).to be false
        end

        it 'can disable 2fa for an admin' do
          user.groups << admin_group
          user.update!({ otp_required_for_login: true })
          post(:disable_two_factor, params: { user_id: user.id })
          expect(response.status).to eq(302)
          user.reload
          expect(user.otp_required_for_login).to be false
        end
      end

      context 'bulk_actions' do
        let(:user1) do
          user = User.new(username: 'user1', email: 'user1@localhost', password: 'test123456')
          user.emails[0].confirmed_at = Time.now.utc
          user.save!
          user
        end

        let(:user2) do
          user = User.new(username: 'user2', email: 'user2@localhost', password: 'test123456')
          user.emails[0].confirmed_at = Time.now.utc
          user.save!
          user
        end

        it 'can bulk disable users' do
          expect(user1.disabled?).to be false
          expect(user2.disabled?).to be false
          post :bulk_action, params: { ids: [user1.id, user2.id], bulk_action: 'disable' }
          user1.reload
          user2.reload
          expect(user1.disabled?).to be true
          expect(user2.disabled?).to be true
        end

        it 'can bulk enable users' do
          user1.update(disabled_at: Time.zone.now)
          user2.update(disabled_at: Time.zone.now)
          expect(user1.disabled?).to be true
          expect(user2.disabled?).to be true
          post :bulk_action, params: { ids: [user1.id, user2.id], bulk_action: 'enable' }
          user1.reload
          user2.reload
          expect(user1.disabled?).to be false
          expect(user2.disabled?).to be false
        end

        it 'can bulk resend confirmation emails' do
          expect do
            perform_enqueued_jobs do
              post :bulk_action, params: { ids: [user1.id, user2.id], bulk_action: 'resend_welcome_email' }
              expect(response.status).to eq(200)
            end
          end.to change { ActionMailer::Base.deliveries.count }.by(2)
          expect(flash[:notice]).to match('Welcome emails will be sent.')
        end

        it 'can bulk reset user passwords' do
          expect do
            perform_enqueued_jobs do
              post :bulk_action, params: { ids: [user1.id, user2.id], bulk_action: 'reset_password' }
              expect(response.status).to eq(200)
            end
          end.to change { ActionMailer::Base.deliveries.count }.by(2)
          expect(flash[:notice]).to match('Password reset emails were successfully requested')
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
