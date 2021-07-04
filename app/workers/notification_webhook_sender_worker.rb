# frozen_string_literal: true

class NotificationWebhookSenderWorker
  include Sidekiq::Worker

  def perform(*args)
    # Do something
  end
end
