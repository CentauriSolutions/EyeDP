# frozen_string_literal: true

SamlIdp.configure do |config|
  # binding.pry
  def config.x509_certificate
    Setting.saml_certificate
  end
  # config.x509_certificate = -> { Setting.saml_certificate }
  #   <<-CERT
  # -----BEGIN CERTIFICATE-----
  # CERTIFICATE DATA
  # -----END CERTIFICATE-----
  # CERT

  def config.secret_key
    Setting.saml_key
  end
  # config.secret_key = -> { Setting.saml_key }
  #   <<-CERT
  # -----BEGIN RSA PRIVATE KEY-----
  # KEY DATA
  # -----END RSA PRIVATE KEY-----
  # CERT

  # config.password = "secret_key_password"
  # config.algorithm = :sha256
  # config.organization_name = "Your Organization"
  # config.organization_url = "http://example.com"

  def config.base_saml_location
    "#{Setting.idp_base}/saml"
  end

  # config.reference_id_generator                                 # Default: -> { UUID.generate }
  def config.single_logout_service_post_location
    "#{Setting.idp_base}/saml/logout"
  end

  def config.single_logout_service_redirect_location
    "#{Setting.idp_base}/saml/logout"
  end

  def config.attribute_service_location
    "#{Setting.idp_base}/saml/attributes"
  end

  def config.single_service_post_location
    "#{Setting.idp_base}/saml/auth"
  end

  def config.session_expiry
    Setting.saml_timeout
  end

  # Principal (e.g. User) is passed in when you `encode_response`
  #
  config.name_id.formats =
    { # All 2.0
      email_address: ->(principal) { principal.try(:email) },
      transient: ->(principal) { principal.try(:id) },
      persistent: ->(p) { p.try(:id) }
    }
  # config.name_id.formats # =>
  #   {                         # All 2.0
  #     email_address: -> (principal) { principal.email_address },
  #     transient: -> (principal) { principal.id },
  #     persistent: -> (p) { p.id },
  #   }
  #   OR
  #
  #   {
  #     "1.1" => {
  #       email_address: -> (principal) { principal.email_address },
  #     },
  #     "2.0" => {
  #       transient: -> (principal) { principal.email_address },
  #       persistent: -> (p) { p.id },
  #     },
  #   }

  # If Principal responds to a method called `asserted_attributes`
  # the return value of that method will be used in lieu of the
  # attributes defined here in the global space. This allows for
  # per-user attribute definitions.
  #
  ## EXAMPLE **
  # class User
  #   def asserted_attributes
  #     {
  #       phone: { getter: :phone },
  #       email: {
  #         getter: :email,
  #         name_format: Saml::XML::Namespaces::Formats::NameId::EMAIL_ADDRESS,
  #         name_id_format: Saml::XML::Namespaces::Formats::NameId::EMAIL_ADDRESS
  #       }
  #     }
  #   end
  # end
  #
  # If you have a method called `asserted_attributes` in your Principal class,
  # there is no need to define it here in the config.

  # config.attributes # =>
  #   {
  #     <friendly_name> => {                                                  # required (ex "eduPersonAffiliation")
  #       "name" => <attrname>                                                # required (ex "urn:oid:1.3.6.1.4.1.5923.1.1.1.1")
  #       "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:uri", # not required
  #       "getter" => ->(principal) {                                         # not required
  #         principal.get_eduPersonAffiliation                                # If no "getter" defined, will try
  #       }                                                                   # `principal.eduPersonAffiliation`, or no values will
  #    }                                                                      # be output
  #
  ## EXAMPLE ##
  # config.attributes = {
  #   GivenName: {
  #     getter: :first_name,
  #   },
  #   SurName: {
  #     getter: :last_name,
  #   },
  # }
  ## EXAMPLE ##

  # config.technical_contact.company = "Example"
  # config.technical_contact.given_name = "Jonny"
  # config.technical_contact.sur_name = "Support"
  # config.technical_contact.telephone = "55555555555"
  # config.technical_contact.email_address = "example@example.com"

  # `identifier` is the entity_id or issuer of the Service Provider,
  # settings is an IncomingMetadata object which has a to_h method that needs to be persisted
  config.service_provider.metadata_persister = lambda { |identifier, settings|
    fname = identifier.to_s.gsub(%r{/|:}, '_')
    FileUtils.mkdir_p(Rails.root.join('cache', 'saml', 'metadata').to_s)
    File.open Rails.root.join("cache/saml/metadata/#{fname}"), 'r+b' do |f|
      Marshal.dump settings.to_h, f
    end
  }

  # `identifier` is the entity_id or issuer of the Service Provider,
  # `service_provider` is a ServiceProvider object. Based on the `identifier` or the
  # `service_provider` you should return the settings.to_h from above
  config.service_provider.persisted_metadata_getter = lambda { |identifier, _service_provider|
    fname = identifier.to_s.gsub(%r{/|:}, '_')
    FileUtils.mkdir_p(Rails.root.join('cache', 'saml', 'metadata').to_s)
    full_filename = Rails.root.join("cache/saml/metadata/#{fname}")
    if File.file?(full_filename)
      File.open full_filename, 'rb' do |f|
        Marshal.load f
      end
    end
  }

  # Find ServiceProvider metadata_url and fingerprint based on our settings
  config.service_provider.finder = lambda { |issuer_or_entity_id|
    # service_providers[issuer_or_entity_id]
    filtered_attributes = ["created_at", "updated_at", "id"]
    idp = SamlServiceProvider.
      find_by(issuer_or_entity_id: issuer_or_entity_id)
    return if idp.nil?
    idp.attributes.
      filter{|k,_| ! filtered_attributes.include?(k)}
  }
end
