# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SAML Flow', type: :request do
  let(:user) do
    user = User.create!(name: 'example name', username: 'example', email: 'test@localhost', password: 'test1234')
    user.confirm!
    user
  end
  let(:users_group) { Group.create!(name: 'users') }
  let(:application) do
    SamlServiceProvider.create!(
      metadata_url: 'https://example.com/saml_metadata',
      issuer_or_entity_id: 'https://example.com',
      response_hosts: ['example.com'],
      display_url: 'example.com', name: 'test'
    )
  end

  let(:user_attributes) do
    {
      'name'           => ['example name'],
      'username'       => ['example'],
      'email'          => ['test@localhost'],
      'groups'         => kind_of(Array)
    }
  end

  def saml_settings(saml_acs_url = 'https://example.com/saml/consume')
    settings = OneLogin::RubySaml::Settings.new
    settings.assertion_consumer_service_url = saml_acs_url
    settings.issuer = 'https://example.com'
    settings.idp_sso_target_url = 'https://example.com/saml/auth'
    settings.assertion_consumer_logout_service_url = 'https://example.com/saml/logout'
    settings.idp_cert_fingerprint = SamlIdp::Default::FINGERPRINT
    settings.name_identifier_format = SamlIdp::Default::NAME_ID_FORMAT
    settings
  end

  def saml_request!
    auth_request = OneLogin::RubySaml::Authrequest.new
    auth_url = auth_request.create(saml_settings('https://example.com/saml/consume'))
    get auth_url
  end

  context 'Logged in user' do
    before do
      Setting.idp_base = 'http://localhost:3000'
      Setting.saml_certificate = File.read(Rails.root.join('myCert.crt'))
      Setting.saml_key = File.read(Rails.root.join('myKey.key'))
      user.groups << users_group
      sign_in user
      application
      saml_request!
    end

    after do
      Setting.idp_base = nil
      Setting.saml_certificate = nil
      Setting.saml_key = nil
      Setting.clear_cache
    end

    it 'gets user attributes' do
      expect(response.body).to match(/id="SAMLResponse" value="(.*)"/)
      match = response.body.match(/id="SAMLResponse" value="(.*)"/)
      saml_response = OneLogin::RubySaml::Response.new Base64.decode64(match[1])
      saml_attrs = saml_response.attributes.to_h
      expect(saml_attrs).to match(user_attributes)
      expect(saml_attrs['groups']).to match([users_group.name])
    end
  end
end
