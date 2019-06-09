# frozen_string_literal: true

class Application < Doorkeeper::Application
  def to_s
    name
  end
end
