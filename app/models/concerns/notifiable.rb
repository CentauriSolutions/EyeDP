# frozen_string_literal: true

module Notifiable
  def notify_for(events, check: nil)
    events.each do |action|
      send "after_#{action}" do |model|
        model.notifiable_callable(check, action)
      end
    end
  end

  def notifiable_callable(check, action)
    return if !check.nil? && !send(check)

    NotificationSetupWorker.perform_async(
      NotificationEvent.new(notifiable_name, id, action, notifiable_attrs).to_json
    )
  end

  private

  def notifiable_attrs
    if respond_to? :notification_attributes
      notification_attributes
    else
      attributes
    end
  end

  def notifiable_name
    if respond_to?(:notifiable_name)
      notifiable_name
    else
      self.class.name.downcase
    end
  end
end
