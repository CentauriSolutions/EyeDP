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
end
