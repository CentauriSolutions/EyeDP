# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EyedP::HTTP do
  include StubRequests

  let(:default_options) { described_class::DEFAULT_TIMEOUT_OPTIONS }

  context 'when reading the response is too slow' do
    before do
      stub_const("#{described_class}::DEFAULT_READ_TOTAL_TIMEOUT", 0.001.seconds)

      WebMock.stub_request(:post, /.*/).to_return do |_request|
        sleep 0.002.seconds
        { body: 'I\m slow', status: 200 }
      end
    end

    let(:options) { {} }

    subject(:request_slow_responder) { described_class.post('http://example.org', **options) }

    specify do
      expect { request_slow_responder }.not_to raise_error
    end

    context 'with use_read_total_timeout option' do
      let(:options) { { use_read_total_timeout: true } }

      it 'raises a timeout error' do
        expect do
          request_slow_responder
        end.to raise_error(EyedP::HTTP::ReadTotalTimeout,
                           /Request timed out after ?([0-9]*[.])?[0-9]+ seconds/)
      end

      context 'and timeout option' do
        let(:options) { { use_read_total_timeout: true, timeout: 10.seconds } }

        it 'overrides the default timeout when timeout option is present' do
          expect { request_slow_responder }.not_to raise_error
        end
      end
    end
  end

  it 'calls a block' do
    WebMock.stub_request(:post, /.*/)

    expect { |b| described_class.post('http://example.org', &b) }.to yield_with_args
  end

  describe 'handle redirect loops' do
    before do
      stub_full_request('http://example.org',
                        method: :any).to_raise(HTTParty::RedirectionTooDeep.new('Redirection Too Deep'))
    end

    it 'handles GET requests' do
      expect { described_class.get('http://example.org') }.to raise_error(EyedP::HTTP::RedirectionTooDeep)
    end

    it 'handles POST requests' do
      expect { described_class.post('http://example.org') }.to raise_error(EyedP::HTTP::RedirectionTooDeep)
    end

    it 'handles PUT requests' do
      expect { described_class.put('http://example.org') }.to raise_error(EyedP::HTTP::RedirectionTooDeep)
    end

    it 'handles DELETE requests' do
      expect { described_class.delete('http://example.org') }.to raise_error(EyedP::HTTP::RedirectionTooDeep)
    end

    it 'handles HEAD requests' do
      expect { described_class.head('http://example.org') }.to raise_error(EyedP::HTTP::RedirectionTooDeep)
    end
  end

  describe 'setting default timeouts' do
    before do
      stub_full_request('http://example.org', method: :any)
    end

    context 'when no timeouts are set' do
      it 'sets default open and read and write timeouts' do
        expect(described_class).to receive(:httparty_perform_request).with(
          Net::HTTP::Get, 'http://example.org', default_options
        ).and_call_original

        described_class.get('http://example.org')
      end
    end

    context 'when :timeout is set' do
      it 'does not set any default timeouts' do
        expect(described_class).to receive(:httparty_perform_request).with(
          Net::HTTP::Get, 'http://example.org', timeout: 1
        ).and_call_original

        described_class.get('http://example.org', timeout: 1)
      end
    end

    context 'when :open_timeout is set' do
      it 'only sets default read and write timeout' do
        expect(described_class).to receive(:httparty_perform_request).with(
          Net::HTTP::Get, 'http://example.org', default_options.merge(open_timeout: 1)
        ).and_call_original

        described_class.get('http://example.org', open_timeout: 1)
      end
    end

    context 'when :read_timeout is set' do
      it 'only sets default open and write timeout' do
        expect(described_class).to receive(:httparty_perform_request).with(
          Net::HTTP::Get, 'http://example.org', default_options.merge(read_timeout: 1)
        ).and_call_original

        described_class.get('http://example.org', read_timeout: 1)
      end
    end

    context 'when :write_timeout is set' do
      it 'only sets default open and read timeout' do
        expect(described_class).to receive(:httparty_perform_request).with(
          Net::HTTP::Put, 'http://example.org', default_options.merge(write_timeout: 1)
        ).and_call_original

        described_class.put('http://example.org', write_timeout: 1)
      end
    end
  end
end
