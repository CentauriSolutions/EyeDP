# frozen_string_literal: true

class WebHook < ApplicationRecord
  has_many :web_hook_logs, dependent: :destroy
  audited

  attr_encrypted :url,
                 key: ENV['DATABASE_ENCRYPTION_KEY'],
                 mode:      :per_attribute_iv,
                 algorithm: 'aes-256-gcm'

  attr_encrypted :token,
                 key: ENV['DATABASE_ENCRYPTION_KEY'],
                 mode:      :per_attribute_iv,
                 algorithm: 'aes-256-gcm'
end
