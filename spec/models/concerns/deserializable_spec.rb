# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deserializable do
  before do
    stub_const('Example', Class.new)
    Example.class_eval do
      include Deserializable
    end
  end
  context 'deserialize' do
    let(:deserializable) { Example.new }

    describe 'boolean' do
      it '"t"' do
        expect(deserializable.deserialize('t', 'boolean')).to eq(true)
      end

      it 'true' do
        expect(deserializable.deserialize(true, 'boolean')).to eq(true)
      end

      it '"true"' do
        expect(deserializable.deserialize('true', 'boolean')).to eq(true)
      end

      it '"1"' do
        expect(deserializable.deserialize('1', 'boolean')).to eq(true)
      end

      it '1' do
        expect(deserializable.deserialize(1, 'boolean')).to eq(true)
      end

      it ':true' do
        expect(deserializable.deserialize(:true, 'boolean')).to eq(true) #  rubocop:disable Lint/BooleanSymbol
      end
    end

    describe 'array' do
      it 'comma' do
        expect(deserializable.deserialize('1,2', 'array')).to eq %w[1 2]
      end

      it 'semicolon' do
        expect(deserializable.deserialize('1;2', 'array')).to eq %w[1 2]
      end

      it 'newline' do
        expect(deserializable.deserialize("1\n2", 'array')).to eq %w[1 2]
      end
    end

    it 'integer' do
      expect(deserializable.deserialize('3', 'integer')).to eq 3
    end
  end
end
