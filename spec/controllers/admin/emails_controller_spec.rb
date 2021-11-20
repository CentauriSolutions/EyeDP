# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::EmailsController, type: :controller do
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

      it "can confirm a user's email" do
        email = Email.create(user: user, address: 'user2@localhost')
        post(:confirm, params: { user_id: user.id, email_id: email.id })
        expect(response.status).to eq(302)
        expect(flash[:notice]).to match('Email was successfully confirmed.')
        email.reload
        expect(email.confirmed?).to be true
      end
    end

    context 'signed in operator' do
      before do
        sign_in(operator)
      end

      it 'returns a 404 code' do
        expect { post(:confirm, params: { user_id: 1, email_id: 1 }) }.to raise_error(ActionController::RoutingError)
      end
    end

    context 'signed in admin' do
      before do
        sign_in(admin)
      end

      it "can confirm a user's email" do
        email = Email.create(user: user, address: 'user2@localhost')
        post(:confirm, params: { user_id: user.id, email_id: email.id })
        expect(response.status).to eq(302)
        expect(flash[:notice]).to match('Email was successfully confirmed.')
        email.reload
        expect(email.confirmed?).to be true
      end
    end

    context 'signed in user' do
      before do
        sign_in(user)
      end
      it 'returns 404 code' do
        expect { post(:confirm, params: { user_id: 1, email_id: 1 }) }.to raise_error(ActionController::RoutingError)
      end
    end

    context 'signed out user' do
      it 'returns 404 code' do
        expect { post(:confirm, params: { user_id: 1, email_id: 1 }) }.to raise_error(ActionController::RoutingError)
      end
    end
  end
end
