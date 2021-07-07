# frozen_string_literal: true

class WebHook < ApplicationRecord
  has_many :web_hook_logs, dependent: :destroy
  audited

  MAX_FAILURES = 10
  FAILURE_THRESHOLD = 3
  INITIAL_BACKOFF = 1.minute
  MAX_BACKOFF = 1.day
  BACKOFF_GROWTH_FACTOR = 2.0

  before_save :setup_template

  attr_encrypted :url,
                 key: ENV['DATABASE_ENCRYPTION_KEY'],
                 mode:      :per_attribute_iv,
                 algorithm: 'aes-256-gcm'

  attr_encrypted :token,
                 key: ENV['DATABASE_ENCRYPTION_KEY'],
                 mode:      :per_attribute_iv,
                 algorithm: 'aes-256-gcm'

  scope :enabled, lambda {
    where(
      'recent_failures <= ? AND (disabled_until IS NULL OR disabled_until < ?)',
      FAILURE_THRESHOLD, Time.current
    )
  }

  def setup_template
    self.template ||= {
      "event": '{{ event_type }}',
      "{{ model_type }}": '{{ model_attributes }}'
    }.to_json
  end

  def next_backoff
    return MAX_BACKOFF if backoff_count >= 8 # Don't really need to ever go over a day

    (INITIAL_BACKOFF * (BACKOFF_GROWTH_FACTOR**backoff_count))
      .clamp(INITIAL_BACKOFF, MAX_BACKOFF)
      .seconds
  end

  def enable!
    return if recent_failures.zero? && disabled_until.nil? && backoff_count.zero?

    update!(recent_failures: 0, disabled_until: nil, backoff_count: 0)
  end

  def backoff!
    update!(disabled_until: next_backoff.from_now, backoff_count: backoff_count.succ.clamp(0, MAX_FAILURES))
  end

  def failed!
    update!(recent_failures: recent_failures + 1) if recent_failures < MAX_FAILURES
  end
end
