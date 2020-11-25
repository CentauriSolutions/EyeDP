# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do # rubocop:disable Metrics/BlockLength
  context 'group_welcome_email' do
    let(:user) { User.create!(username: 'user', email: 'user@localhost', password: 'test1234') }
    let(:group) { Group.create!(name: 'administrators') }

    let(:mail) { UserMailer.group_welcome_email(user, group) }
    it 'renders the headers' do
      expect(mail.subject).to eq('Welcome to administrators')
      expect(mail.to).to eq(['user@localhost'])
      expect(mail.from).to eq(['noreply@example.com'])
    end

    it 'is customized with welcome_email' do
      group.welcome_email = 'Hey there'
      group.save
      expect(mail.body.encoded).to match('Hey there')
    end
  end

  context 'force_reset_password_email' do
    let(:user) { User.create!(username: 'user', email: 'user@localhost', password: 'test1234') }
    let(:mail) { UserMailer.force_reset_password_email(user, 'test token') }

    it 'renders the headers' do
      expect(mail.subject).to eq('Password Changed')
      expect(mail.to).to eq(['user@localhost'])
      expect(mail.from).to eq(['noreply@example.com'])
    end

    it 'supports a default' do
      expect(mail.body.encoded).to match('reset your password so you must now update it')
    end

    it 'can be customized' do
      Setting.admin_reset_email_template = 'this is a test!'
      expect(mail.body.encoded).to match('this is a test')
    end
  end

  context 'admin_welcome_email' do
    let(:user) { User.create!(username: 'user', email: 'user@localhost', password: 'test1234') }
    let(:mail) { UserMailer.admin_welcome_email(user, 'test token') }

    it 'renders the headers' do
      expect(mail.subject).to eq('Your account has been created')
      expect(mail.to).to eq(['user@localhost'])
      expect(mail.from).to eq(['noreply@example.com'])
    end

    it 'supports a default' do
      expect(mail.body.encoded).to match('has created an account for you')
    end

    it 'can be customized' do
      Setting.admin_welcome_email_template = 'this is a test!'
      expect(mail.body.encoded).to match('this is a test')
    end
  end
end
