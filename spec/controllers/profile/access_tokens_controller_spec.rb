# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Profile::AccessTokensController, type: :controller do
  let(:user) do
    user = User.create!(username: 'example', email: 'test@localhost', password: 'test123456')
    user.confirm!
    user
  end

  before do
    sign_in(user)
  end

  context 'Without permission' do
    it "doesn't allow a non-permitted user to view" do
      expect { get :index }.to raise_error(ActionController::RoutingError)
    end

    it "doesn't allow a non-permitted user to create" do
      expect do
        post :create, params: { access_token: { user_id: user.id } }
      end.to raise_error(ActionController::RoutingError)
    end
  end

  context 'With permission' do
    let(:group) { Group.create!(name: 'access tokens', permit_token: true) }

    before do
      user.groups << group
    end

    it 'allows permitted user to view' do
      get 'index'
      expect(response.status).to eq(200)
    end

    it 'allows permitted user to create' do
      expect(user.access_tokens.count).to eq(0)
      post :create, params: { access_token: { user_id: user.id } }
      expect(response.status).to eq(302)
      expect(user.access_tokens.count).to eq(1)
    end
  end
end
