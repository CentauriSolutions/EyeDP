# frozen_string_literal: true

# This class is used as a proxy for all outbounding http connection
# coming from callbacks, services and hooks. The direct use of the HTTParty
# is discouraged because it can lead to several security problems, like SSRF
# calling internal IP or services.
module EyedP
  class HTTP
    BlockedUrlError = Class.new(StandardError)
    RedirectionTooDeep = Class.new(StandardError)
    ReadTotalTimeout = Class.new(Net::ReadTimeout)

    HTTP_TIMEOUT_ERRORS = [
      Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout, EyedP::HTTP::ReadTotalTimeout
    ].freeze
    HTTP_ERRORS = HTTP_TIMEOUT_ERRORS + [
      SocketError, OpenSSL::SSL::SSLError, OpenSSL::OpenSSLError,
      Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::EHOSTUNREACH,
      EyedP::HTTP::BlockedUrlError, EyedP::HTTP::RedirectionTooDeep
    ].freeze

    DEFAULT_TIMEOUT_OPTIONS = {
      open_timeout: 10,
      read_timeout: 20,
      write_timeout: 30
    }.freeze
    DEFAULT_READ_TOTAL_TIMEOUT = 20.seconds

    include HTTParty

    class << self
      alias httparty_perform_request perform_request
    end

    def self.perform_request(http_method, path, options, &block) # rubocop:disable Metrics/MethodLength
      options_with_timeouts =
        if options.key?(:timeout)
          options
        else
          options.with_defaults(DEFAULT_TIMEOUT_OPTIONS)
        end

      unless options.key?(:use_read_total_timeout)
        return httparty_perform_request(http_method, path, options_with_timeouts, &block)
      end

      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      read_total_timeout = options.fetch(:timeout, DEFAULT_READ_TOTAL_TIMEOUT)

      httparty_perform_request(http_method, path, options_with_timeouts) do |fragment|
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
        raise ReadTotalTimeout, "Request timed out after #{elapsed} seconds" if elapsed > read_total_timeout

        block&.call fragment
      end
    rescue HTTParty::RedirectionTooDeep
      raise RedirectionTooDeep
    rescue *HTTP_ERRORS => e
      raise e
    end

    def self.try_get(path, options = {}, &block)
      get(path, options, &block)
    rescue *HTTP_ERRORS
      nil
    end
  end
end
