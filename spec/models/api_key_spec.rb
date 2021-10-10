# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiKey, type: :model do
  it { should be_audited }
end
