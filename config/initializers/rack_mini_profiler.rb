# frozen_string_literal: true

url = ENV['REDIS_URL'] || 'redis://localhost:6379'

if url
  Rack::MiniProfiler.config.storage_options = { url: }
  Rack::MiniProfiler.config.storage = Rack::MiniProfiler::RedisStore
end
