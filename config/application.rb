# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'dotenv'

Dotenv.load if Rails.env.development?

# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
require 'sprockets/railtie'
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module EyedP
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # nil will use the "default" queue
    config.action_mailer.deliver_later_queue_name = nil # defaults to "mailers"
    config.active_storage.queues.analysis   = nil       # defaults to "active_storage_analysis"
    config.active_storage.queues.purge      = nil       # defaults to "active_storage_purge"
    config.active_storage.queues.mirror     = nil       # defaults to "active_storage_mirror"
    # config.active_storage.queues.purge    = :low      # alternatively, put purge jobs in the `low` queue

    config.active_job.queue_adapter = :sidekiq

    # The new autoloader (Zeitwerk) in the 6.0 defaults breaks some of the Devise
    # issues, so it's a TODO to resolve the below autoloading issues.
    config.autoloader = :classic

    config.autoload_paths += %W[
      #{config.root}/app/workers
      #{config.root}/app/wervices
      #{config.root}/lib
    ]

    config.eager_load_paths += %W[
      #{config.root}/app/workers
      #{config.root}/app/wervices
      #{config.root}/lib
    ]

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.generators do |g|
      g.scaffold_stylesheet false
    end

    config.action_mailer.default_url_options = { host: ENV['EMAIL_DOMAIN'] }
  end
end
