# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.1'

gem 'acts_as_tree'

# Supported DBs
# TODO: add MySQL support -
# gem 'mysql2', '~> 0.4.10', group: :mysql
gem 'pg', '~> 1.1', group: :postgresql

gem 'puma', '~> 5.6'
gem 'rails', '~> 6.1'
gem 'sass-rails', '~> 6.0'

# There is no explicit dependency on Nokogiri in EyeDP but this is being
# updated to protect against a low severity security issue:
# https://github.com/advisories/GHSA-vr8q-g5c7-m54m
gem 'nokogiri', '>= 1.11.0.rc4'

gem 'bcrypt', '>= 3.1.13'
gem 'uglifier', '>= 1.3.0'

gem 'jbuilder', '~> 2.5'
gem 'redis', '~> 4.0'
gem 'redis-actionpack'
# gem 'turbolinks', '~> 5'

gem 'bootsnap', '>= 1.3.2', require: false

gem 'dotenv', '~> 2.5.0'
gem 'rails-i18n'

gem 'devise'
gem 'devise_fido_usf'
gem 'devise-i18n'
gem 'devise-multi_email', github: 'centaurisolutions/devise-multi_email'
gem 'friendly_id'
gem 'webauthn'
# Do TOTP 2FA
gem 'devise-two-factor', github: 'tinfoil/devise-two-factor', branch: 'main'
gem 'rqrcode'

# Translations
gem 'translation'

# Audit Logs
gem 'audited'

gem 'bootstrap', '~> 4.4.1'
gem 'bootstrap_form', '>= 4.2.0'
gem 'font-awesome-rails'
gem 'jquery-rails'
gem 'will_paginate'
gem 'will_paginate-bootstrap4'

# These version requirements are copied up from doorkeeper-openid_connect
gem 'doorkeeper', '>= 5.5', '< 5.7'
gem 'doorkeeper-openid_connect'

gem 'sentry-rails'
gem 'sentry-ruby'

# gem 'ledermann-rails-settings'
# gem 'rails-settings-cached'

# profiling
gem 'rack-mini-profiler'
# For memory profiling
gem 'memory_profiler'
# For call-stack profiling flamegraphs
gem 'stackprof'

gem 'tipsy-rails'

# SAML the things!
gem 'saml_idp', '< 0.14'

gem 'groupdate'

gem 'liquid'
gem 'liquid-autoescape'

gem 'attr_encrypted', '~> 3.1.0'
gem 'httparty'
gem 'sidekiq'

gem 'sudo_rails'

gem 'rexml', '~> 3.2', '>= 3.2.5'

group :development, :test do
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 4'
end

group :development do
  gem 'listen', '>= 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  gem 'annotate'
  gem 'awesome_print'
  gem 'bullet'
  gem 'rails-erd'

  gem 'brakeman', require: false
  gem 'overcommit'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false

  gem 'guard'
  gem 'guard-bundler', require: false
  # gem 'guard-livereload', require: false
  # gem 'rack-livereload'

  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'web-console', '>= 3.3.0'

  gem 'bcrypt_pbkdf',       require: false
  gem 'capistrano',         require: false
  gem 'capistrano3-puma',   require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-rails',   require: false
  gem 'capistrano-rvm',     require: false
  gem 'ed25519',            require: false
end

group :test do
  gem 'database_cleaner-active_record'
  gem 'faker'
  gem 'ruby-saml', '>= 1.7.2'
  gem 'shoulda'
  gem 'simplecov',      require: false
  gem 'simplecov-lcov', require: false
  gem 'timecop'
  gem 'webmock'
end
