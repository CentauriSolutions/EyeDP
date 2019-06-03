# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.2'

gem 'acts_as_tree'

# Supported DBs
# TODO: add MySQL support -
# gem 'mysql2', '~> 0.4.10', group: :mysql
gem 'pg', '~> 1.1', group: :postgresql

gem 'puma', '~> 3.11'
gem 'rails', '5.2.3'
gem 'sass-rails', '~> 5.0'

gem 'bcrypt', '>= 3.1.13'
gem 'uglifier', '>= 1.3.0'

gem 'jbuilder', '~> 2.5'
gem 'redis', '~> 4.0'
gem 'turbolinks', '~> 5'

gem 'bootsnap', '>= 1.1.0', require: false

gem 'rails-i18n'

gem 'devise'
gem 'devise-i18n'
gem 'friendly_id'
gem 'will_paginate'
gem 'will_paginate-bootstrap4'

gem 'bootstrap', '~> 4.3.1'
gem 'font-awesome-rails'
gem 'jquery-rails'

# gem 'ledermann-rails-settings'
# gem 'rails-settings-cached'

# SAML the things!
gem 'saml_idp'

group :development, :test do
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 3.8'
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

  gem 'guard'
  gem 'guard-bundler', require: false
  # gem 'guard-livereload', require: false
  # gem 'rack-livereload'

  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'web-console', '>= 3.3.0'
end
