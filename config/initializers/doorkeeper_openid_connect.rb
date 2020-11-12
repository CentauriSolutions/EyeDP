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
    User.active.find_by(id: access_token.resource_owner_id)
  end

  auth_time_from_resource_owner(&:current_sign_in_at)

  subject do |user|
    # hash the user's ID with the Rails secret_key_base to avoid revealing it
    Digest::SHA256.hexdigest "#{user.id}-#{Rails.application.secrets.secret_key_base}"
  end

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

    claim :email_verified do |_resource_owner|
      true
    end

    claim :groups do |resource_owner|
      resource_owner.groups || []
    end

    claim :name do |resource_owner|
      # read_name is aliased to name in the User model, and is called real_name
      # here because of a doorkeeper issue where calling `.name` ends up
      # raising an exception.
      resource_owner.try(:real_name) or resource_owner.username
    end

    claim :nickname, &:username

    claim :preferred_username, &:username

    # claim :preferred_username, scope: :openid do |resource_owner, scopes, access_token|
    #   # Pass the resource_owner's preferred_username if the application has
    #   # `profile` scope access. Otherwise, provide a more generic alternative.
    #   scopes.exists?(:profile) ? resource_owner.username : "summer-sun-9449"
    # end

    claim :profile do |_resource_owner|
      nil
    end

    claim :address do |_resource_owner|
      nil
    end

    claim :phone do |_resource_owner|
      nil
    end
  end
end
