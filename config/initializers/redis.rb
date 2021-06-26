# frozen_string_literal: true

url = ENV['REDIS_URL'] || 'redis://localhost:6379'

if url
  Sidekiq.configure_server do |config|
    config.redis = { url: url }
  end
  Sidekiq.configure_client do |config|
    config.redis = { url: url }
  end
  Redis.current = Redis.new(url: url)
end
