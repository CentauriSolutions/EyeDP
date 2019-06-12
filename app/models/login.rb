# frozen_string_literal: true

# == Schema Information
#
# Table name: logins
#
#  id                    :uuid             not null, primary key
#  service_provider_type :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  service_provider_id   :uuid
#  user_id               :uuid
#
# Indexes
#
#  index_logins_on_service_provider_type_and_service_provider_id  (service_provider_type,service_provider_id)
#  index_logins_on_user_id                                        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class Login < ApplicationRecord
  belongs_to :user
  belongs_to :service_provider, polymorphic: true
end
