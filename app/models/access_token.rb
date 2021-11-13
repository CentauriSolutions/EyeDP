# frozen_string_literal: true

class AccessToken < ApplicationRecord
  belongs_to :user

  after_initialize :setup_token

  def setup_token
    self.token ||= SecureRandom.hex(32)
  end
end
