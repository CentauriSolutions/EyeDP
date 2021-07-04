# frozen_string_literal: true

class NotificationEvent
  attr_accessor :model_type, :model_id, :attributes

  attr_reader :event_type

  def initialize(model_type = nil, model_id = nil, event_type = nil, attributes = nil) # rubocop:disable Metrics/ParameterLists
    self.model_type = model_type if model_type
    self.model_id = model_id if model_id
    self.event_type = event_type if event_type
    self.attributes = attributes if attributes
  end

  def event_type=(value)
    value = value.downcase
    raise "#{value} is not a valid event type" unless %w[create update delete].include? value

    @event_type = value
  end

  def []=(key, value)
    send("#{key}=", value)
  end

  def [](key)
    send(key)
  end
end
