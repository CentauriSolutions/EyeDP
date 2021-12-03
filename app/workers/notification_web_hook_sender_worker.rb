# frozen_string_literal: true

class NotificationWebHookSenderWorker
  include Sidekiq::Worker

  def perform(webhook_id, event) # rubocop:disable Metrics/MethodLength
    hook = WebHook.find(webhook_id)
    event_raw = JSON.parse(event)
    template = Liquid::Template.parse(hook.template)
    body = template.render(event_raw, [WebHookFilters])

    template = Liquid::Template.parse(hook.headers)
    headers = template.render(event_raw, [WebHookFilters])
    headers = begin
      JSON.parse(headers)
    rescue JSON::ParserError
      nil
    end
    WebHookService.new(
      hook, body, headers, event
    ).run
  end
end

module WebHookFilters
  def random_hash(length)
    SecureRandom.hex(length)
  end
end
