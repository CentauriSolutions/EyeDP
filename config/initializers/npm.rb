# frozen_string_literal: true

system 'npm install' if Rails.env.development? || Rails.env.test?
