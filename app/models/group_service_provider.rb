# frozen_string_literal: true

class GroupServiceProvider < ApplicationRecord
  belongs_to :group
  belongs_to :service_provider, polymorphic: true
end
