# frozen_string_literal: true

class NotificationSetupWorker
  include Sidekiq::Worker

  def perform(event)
    # Do something
    notification_event = JSON.parse(event, object_class: NotificationEvent)

    Rails.logger.info "Identifying notifications to send for event: #{notification_event}"
    scope = "#{notification_event.model_type}_#{notification_event.event_type}_events"

    WebHook.enabled.where(scope => true).pluck(:id).each do |hook_id|
      NotificationWebHookSenderWorker.perform_async(hook_id, event)
    end
  end
end
