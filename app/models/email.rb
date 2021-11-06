# frozen_string_literal: true

class Email < ApplicationRecord
  belongs_to :user

  validates :address, presence: true, uniqueness: { case_sensitive: false }

  def email
    address
  end

  def email=(thing)
    self.address = thing
  end

  def will_save_change_to_email?
    will_save_change_to_address?
  end

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end
end
