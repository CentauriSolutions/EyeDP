# frozen_string_literal: true

class Email < ApplicationRecord
  belongs_to :user
  audited only: %i[address primary]
  before_validation :normalize_address

  validates :address, presence: true, uniqueness: { case_sensitive: false }

  def self.confirmed
    where.not(confirmed_at: nil)
  end

  def email
    address
  end

  def email=(thing)
    self.address = thing
  end

  def will_save_change_to_email?
    will_save_change_to_address?
  end

  def send_reset_password_instructions(token)
    send_reset_password_instructions_notification(token)

    token
  end

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  private

  def normalize_address
    self.address = address.downcase
  end
end
