# frozen_string_literal: true

# == Schema Information
#
# Table name: oauth_applications
#
#  id           :uuid             not null, primary key
#  confidential :boolean          default(TRUE), not null
#  name         :string           not null
#  redirect_uri :text             not null
#  scopes       :string           default(""), not null
#  secret       :string           not null
#  uid          :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_oauth_applications_on_uid  (uid) UNIQUE
#

class Application < Doorkeeper::Application
  audited

  has_many :logins, as: :service_provider, dependent: :destroy
  has_many :group_service_providers, as: :service_provider, dependent: :destroy
  has_many :groups, through: :group_service_providers

  has_many :custom_attribute_service_providers, dependent: :destroy
  has_many :custom_userdata_types, through: :custom_attribute_service_providers

  def to_s
    name
  end
end
