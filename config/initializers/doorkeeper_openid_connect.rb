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
    # This is kept as a block instead of a callable proc in case it is desired, later, to
    # increase privacy via the confidential parameter
    claim :email, scope: :openid do |resource_owner| # rubocop:disable Style/SymbolProc
      # Pass the resource_owner's email
      resource_owner.email
    end

    claim :email_verified do |_resource_owner|
      true
    end

    claim :groups, scope: :openid do |resource_owner|
      (resource_owner.asserted_groups || []).map(&:name)
    end

    claim :name, scope: :openid do |resource_owner|
      # real_name is aliased to name in the User model, and is called real_name
      # here because of a doorkeeper issue where calling `.name` ends up
      # raising an exception.
      resource_owner.try(:real_name) or resource_owner.username
    end

    # This is kept as a block instead of a callable proc in case it is desired, later, to
    # increase privacy via the confidential parameter
    claim :username, scope: :openid do |resource_owner| # rubocop:disable Style/SymbolProc
      # Pass the resource_owner's username
      resource_owner.username
    end

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
