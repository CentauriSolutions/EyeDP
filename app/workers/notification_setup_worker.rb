# frozen_string_literal: true

class NotificationSetupWorker
  include Sidekiq::Worker

  def self.perform_async(notification_event)
    # Override this Sidekiq method to ensure we serialize the Event in
    # a way that lets us recreate it later
    super(notification_event.to_json)
  end

  def perform(event)
    # Do something
    notification_event = JSON.parse(event, object_class: NotificationEvent)

    Rails.logger.info "Identifying notifications to send for event: #{notification_event}"
  end
end
