
EyedP::Application.config.session_store :cookie_store,
    key: '_eyed_p_session',
    domain: ENV['SSO_DOMAIN'] || :all,
    tld_length: 2,
    secure: Rails.env.production?
