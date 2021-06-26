# frozen_string_literal: true

url = ENV['REDIS_URL'] || 'redis://localhost:6379'
EyedP::Application.config.session_store :redis_store,
                                        key: '_eyed_p_session',
                                        domain: ENV['SSO_DOMAIN'] || :all,
                                        tld_length: 2,
                                        secure: Rails.env.production? && !ENV['DISABLE_SSL'],
                                        servers: [{
                                          url: url,
                                          serializer: JSON
                                        }]
