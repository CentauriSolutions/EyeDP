# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::AuditsController, type: :controller do
  include ActiveJob::TestHelper
  render_views

  let(:user) do
    user = User.create!(username: 'user', email: 'user@localhost', password: 'test123456')
    user.confirm!
    user
  end
  let(:group) { Group.create!(name: 'administrators', admin: true) }
  let(:admin) do
    user = User.create!(username: 'admin', email: 'admin@localhost', password: 'test123456')
    user.groups << group
    user.confirm!
    user
  end

  before do
    sign_in(admin)
  end

  it 'does not show encrypted passwords' do
    user.password = 'new password 123'
    user.save
    get :index
    expect(response.status).to eq(200)
    expect(response.body).to include('encrypted_password: &quot;&lt;REDACTED&gt;&quot;')
  end

  it 'does not show password reset tokens' do
    # The user creation above will trigger the password reset token
    get :index
    expect(response.status).to eq(200)
    expect(response.body).to include('reset_password_token: &quot;&lt;REDACTED&gt;&quot;')
  end

  it 'does not show oidc_signing_key' do
    secret1 = 'this is a secret!'
    Setting.oidc_signing_key = secret1

    get :index
    expect(response.status).to eq(200)
    sha = OpenSSL::Digest::SHA1.hexdigest(secret1)
    expect(response.body).to include("setting: oidc_signing_key\nvalue: &#39;Sha1 of secret: #{sha}&#39")

    secret2 = 'this is also a secret!'
    Setting.oidc_signing_key = secret2

    get :index
    expect(response.status).to eq(200)
    sha = OpenSSL::Digest::SHA1.hexdigest(secret2)
    expect(response.body).to include("setting: oidc_signing_key\nvalue: &#39;Sha1 of secret: #{sha}&#39")
  end

  it 'does not show SAML key' do
    secret1 = 'this is a secret!'
    Setting.saml_key = secret1

    get :index
    expect(response.status).to eq(200)
    sha = OpenSSL::Digest::SHA1.hexdigest(secret1)
    expect(response.body).to include("setting: saml_key\nvalue: &#39;Sha1 of secret: #{sha}&#39")

    secret2 = 'this is also a secret!'
    Setting.saml_key = secret2

    get :index
    expect(response.status).to eq(200)
    sha = OpenSSL::Digest::SHA1.hexdigest(secret2)
    expect(response.body).to include("setting: saml_key\nvalue: &#39;Sha1 of secret: #{sha}&#39")
  end

  it 'does show SAML certificate' do
    Setting.saml_certificate = 'this is not a secret!'

    get :index
    expect(response.status).to eq(200)
    # binding.pry
    expect(response.body).to include("setting: saml_certificate\nvalue: this is not a secret!")
  end
end
