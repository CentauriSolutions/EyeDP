# frozen_string_literal: true

Doorkeeper::OpenidConnect.configure do
  def @config.issuer
    Setting.idp_base
  end

  def @config.signing_key
    Setting.oidc_signing_key
  end

  subject_types_supported [:public]

  resource_owner_from_access_token do |access_token|
    User.find_by(id: access_token.resource_owner_id)
  end

  auth_time_from_resource_owner(&:current_sign_in_at)

  reauthenticate_resource_owner do |resource_owner, return_to|
    store_location_for resource_owner, return_to
    sign_out resource_owner
    redirect_to new_user_session_url
  end

  subject do |resource_owner, application|
    # or if you need pairwise subject identifier, implement like below:
    Digest::SHA256.hexdigest("#{resource_owner.id}#{URI.parse(application.redirect_uri).host}")
  end

  # Protocol to use when generating URIs for the discovery endpoint,
  # for example if you also use HTTPS in development
  # protocol do
  #   :https
  # end

  # Expiration time on or after which the ID Token MUST NOT be accepted for processing. (default 120 seconds).
  # expiration 600

  claims do
    claim :email, &:email

    claim :groups do |resource_owner|
      scopes.exists?(:groups) ? resource_owner.groups : []
    end
  end
end
