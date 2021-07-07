# frozen_string_literal: true

class WebHookService
  attr_accessor :hook, :data, :request_options, :event

  def initialize(hook, data, event)
    @hook = hook
    @data = data
    @event = event
    @request_options = {
      timeout: Setting.webhook_timeout,
      use_read_total_timeout: true
    }
  end

  def run # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response = if parsed_url.userinfo.blank?
                 make_request(hook.url)
               else
                 make_request_with_auth
               end
    execution_duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
    WebHookLog.create(
      web_hook: hook,
      execution_duration: execution_duration,
      request_data: data,
      response_data: response.body,
      response_headers: response.headers,
      response_status: response.code,
      trigger: event.to_json
    )
    case response_category(response)
    when :ok
      hook.enable!
    when :error
      hook.backoff!
    when :failed
      hook.failed!
    end
  end

  private

  def response_category(response)
    if response.success? || response.redirection?
      :ok
    elsif response.internal_server_error?
      :error
    else
      :failed
    end
  end

  def parsed_url
    @parsed_url ||= URI.parse(hook.url)
  end

  def make_request(url, basic_auth: false)
    EyedP::HTTP.post(url,
                     body: data,
                     headers: build_headers,
                     verify: hook.enable_ssl_verification,
                     basic_auth: basic_auth,
                     **request_options)
  end

  def make_request_with_auth
    post_url = hook.url.gsub("#{parsed_url.userinfo}@", '')
    basic_auth = {
      username: CGI.unescape(parsed_url.user),
      password: CGI.unescape(parsed_url.password.presence || '')
    }
    make_request(post_url, basic_auth: basic_auth)
  end

  def build_headers
    @build_headers ||= {
      'Content-Type' => 'application/json',
        'User-Agent' => 'EyeDP/1.0'
    }.tap do |hash|
      hash['EyeDP-Token'] = hook.token if hook.token.present?
    end
  end

  # Make response headers more stylish
  # Net::HTTPHeader has downcased hash with arrays: { 'content-type' => ['text/html; charset=utf-8'] }
  # This method format response to capitalized hash with strings: { 'Content-Type' => 'text/html; charset=utf-8' }
  def format_response_headers(response)
    response.headers.each_capitalized.to_h
  end

  def safe_response_body(response)
    return '' unless response.body

    response.body.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
  end
end
