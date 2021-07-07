# frozen_string_literal: true

require 'webmock'
require 'webmock/rspec'

# This prevents Selenium/WebMock from spawning thousands of connections
# while waiting for an element to appear via Capybara's find:
# https://github.com/teamcapybara/capybara/issues/2322#issuecomment-619321520
def webmock_enable_with_http_connect_on_start!
  webmock_enable!(net_http_connect_on_start: true)
end

def webmock_enable!(options = {})
  WebMock.disable_net_connect!(
    {
      allow_localhost: true,
      allow: []
    }.merge(options)
  )
end

webmock_enable!
