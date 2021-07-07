# frozen_string_literal: true

class NotificationWebHookSenderWorker
  include Sidekiq::Worker

  def perform(webhook_id, event)
    hook = WebHook.find(webhook_id)
    template = Liquid::Template.parse(hook.template)
    body = template.render(JSON.parse(event))
    WebHookService.new(
      hook, body, event
    ).run
  end
end
