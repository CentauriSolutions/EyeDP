# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
Doorkeeper::OpenidConnect.configure do
  def @config.issuer
    Setting.oidc_issuer
  end

  def @config.signing_key
    Setting.oidc_signing_key
  end

  subject_types_supported [:public]

  resource_owner_from_access_token do |access_token|
    # Example implementation:
    User.find_by(id: access_token.resource_owner_id)
  end

  auth_time_from_resource_owner do |resource_owner|
    # Example implementation:
    # resource_owner.current_sign_in_at
  end

  reauthenticate_resource_owner do |resource_owner, return_to|
    # Example implementation:
    store_location_for resource_owner, return_to
    sign_out resource_owner
    redirect_to new_user_session_url
  end

  subject do |resource_owner, application|
    # Example implementation:
    # resource_owner.id

    # or if you need pairwise subject identifier, implement like below:
    Digest::SHA256.hexdigest("#{resource_owner.id}#{URI.parse(application.redirect_uri).host}")
  end

  # Protocol to use when generating URIs for the discovery endpoint,
  # for example if you also use HTTPS in development
  protocol do
    :https
  end

  # Expiration time on or after which the ID Token MUST NOT be accepted for processing. (default 120 seconds).
  # expiration 600

  claims do
    claim :email, &:email

    # claim :full_name do |resource_owner|
    #   "#{resource_owner.first_name} #{resource_owner.last_name}"
    # end

    # claim :preferred_username, scope: :openid do |resource_owner, scopes, access_token|
    #   # Pass the resource_owner's preferred_username if the application has
    #   # `profile` scope access. Otherwise, provide a more generic alternative.
    #   scopes.exists?(:profile) ? resource_owner.preferred_username : "summer-sun-9449"
    # end

    claim :groups do |resource_owner|
      scopes.exists?(:groups) ? resource_owner.groups : []
    end
  end
end
# rubocop:enable Metrics/BlockLength
