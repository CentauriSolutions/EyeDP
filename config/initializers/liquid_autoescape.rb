# frozen_string_literal: true

Liquid::Autoescape.configure do |config|
  config.global = true
  config.trusted_filters << :to_json
end
