# frozen_string_literal: true

WebAuthn.configure do |config|
  # This value needs to match `window.location.origin` evaluated by
  # the User Agent during registration and authentication ceremonies.
  def config.origin
    "#{Rails.env.production? && !ENV['DISABLE_SSL'] ? 'https' : 'http'}://#{Setting.idp_base}"
  end

  # Relying Party name for display purposes
  config.rp_name = 'EyeDP'

  # Optionally configure a client timeout hint, in milliseconds.
  # This hint specifies how long the browser should wait for an
  # attestation or an assertion response.
  # This hint may be overridden by the browser.
  # https://www.w3.org/TR/webauthn/#dom-publickeycredentialcreationoptions-timeout
  config.credential_options_timeout = 120_000

  # You can optionally specify a different Relying Party ID
  # (https://www.w3.org/TR/webauthn/#relying-party-identifier)
  # if it differs from the default one.
  #
  # In this case the default would be "auth.example.com", but you can set it to
  # the suffix "example.com"
  #
  # config.rp_id = "example.com"
end
