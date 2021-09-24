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
        name = if model.respond_to?(:notifiable_name)
                 model.notifiable_name
               else
                 model.class.name.downcase
               end
        NotificationSetupWorker.perform_async(
          NotificationEvent.new(name, model.id, action, attrs).to_json
        )
      end
    end
  end
end
