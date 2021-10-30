class Email < ApplicationRecord
  belongs_to :user

  validates :address, presence: true, uniqueness: { case_sensitive: false } # rubocop:disable Rails/UniqueValidationWithoutIndex

  def email
    address
  end

  def email=thing
    address=thing
  end

  def will_save_change_to_email?
    will_save_change_to_address?
  end
end
