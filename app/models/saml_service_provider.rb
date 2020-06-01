# frozen_string_literal: true

# == Schema Information
#
# Table name: saml_service_providers
#
#  id                  :uuid             not null, primary key
#  fingerprint         :text
#  metadata_url        :text             not null
#  response_hosts      :string           is an Array
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  issuer_or_entity_id :text             not null
#
# Indexes
#
#  index_saml_service_providers_on_issuer_or_entity_id  (issuer_or_entity_id) UNIQUE
#

class SamlServiceProvider < ApplicationRecord
  has_many :logins, :as => :service_provider, dependent: :destroy

  def to_s
    issuer_or_entity_id
  end
end
