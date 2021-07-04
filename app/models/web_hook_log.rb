# frozen_string_literal: true

class WebHookLog < ApplicationRecord
  belongs_to :web_hook
end
