# frozen_string_literal: true

class NotificationEvent
  attr_accessor :model_type, :model_id, :model_attributes

  attr_reader :event_type

  def initialize(model_type = nil, model_id = nil, event_type = nil, model_attributes = nil) # rubocop:disable Metrics/ParameterLists
    self.model_type = model_type if model_type
    self.model_id = model_id if model_id
    self.event_type = event_type if event_type
    self.model_attributes = model_attributes || {}
  end

  def event_type=(value)
    value = value.to_s.downcase
    raise "#{value} is not a valid event type" unless %w[create update destroy].include? value

    @event_type = value
  end

  def []=(key, value)
    if respond_to?("#{key}=")
      send("#{key}=", value)
    else
      model_attributes[key] = value
    end
  end

  def [](key)
    send(key)
  end
end
