# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Profile::EmailsController, type: :controller do
  let(:user) do
    user = User.create!(username: 'example', email: 'test@localhost', password: 'test123456')
    user.confirm!
    user
  end

  before do
    sign_in(user)
  end

  context 'delete' do
    it 'can add additional emails' do
      expect(user.emails.count).to eq(1)
      post :create, params: { email: { address: 'test2@localhost' } }
      expect(user.emails.count).to eq(2)
    end

    it 'can delete additional emails' do
      email = Email.create!(user: user, address: 'test2@Localhost', confirmed_at: Time.zone.now)
      expect(user.emails.count).to eq(2)
      delete :destroy, params: { id: email.id }
      user.reload
      expect(user.emails.count).to eq(1)
    end

    it 'cannot delete primary email' do
      Email.create!(user: user, address: 'test2@Localhost', confirmed_at: Time.zone.now)
      expect(user.emails.count).to eq(2)
      delete :destroy, params: { id: user.primary_email_record.id }
      user.reload
      expect(user.emails.count).to eq(2)
      expect(flash[:notice]).to match(/cannot delete your primary email/)
    end
  end
end
