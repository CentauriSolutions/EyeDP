# frozen_string_literal: true

module Notifiable
  def notify_for(events) # rubocop:disable Metrics/MethodLength
    events.each do |action|
      send "after_#{action}" do |model|
        attrs = if model.respond_to? :notification_attributes
                  model.notification_attributes
                else
                  model.attributes
                end
        NotificationSetupWorker.perform_async(
          NotificationEvent.new(
            model_type: model.class.name,
            model_id: model.id,
            event_type: 'create',
            attributes: attrs
          )
        )
      end
    end
  end
end
