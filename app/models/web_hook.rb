# frozen_string_literal: true

class WebHook < ApplicationRecord
  has_many :web_hook_logs, dependent: :destroy
end
