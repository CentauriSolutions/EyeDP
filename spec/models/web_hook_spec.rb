# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebHook, type: :model do
  it { should be_audited }
end
