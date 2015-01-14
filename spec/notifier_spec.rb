require 'spec_helper'
require 'oj'

describe GelfLogger::Notifier do
  let(:notifier){ GelfLogger::Notifier.new('test.example.com', 12345) }
  let(:sender){ GelfLogger::Sender.new('test.example.com', 12345) }

  before do
    notifier.sender = sender
  end

  describe 'generate_message' do
    let(:hash){ notifier.send(:generate_message, 'Hello World') }

    it 'sets version to default' do
      expect(hash[:version]).to eq GelfLogger::SPEC_VERSION
    end

    it 'sets host' do
      expect(hash[:host]).to eq Socket.gethostname
    end

    it 'sets the timestamp' do
      now = Time.now.utc.to_f
      expect((hash[:timestamp] - now).abs).to be <= 1
    end

    context 'string' do
      it 'sets short message' do
        expect(hash[:short_message]).to eq 'Hello World'
      end
    end

    context 'hash' do
      let(:hash){ notifier.send(:generate_message, { hello: 'world' }) }

      it 'uses given hash' do
        expect(hash[:hello]).to eq 'world'
      end

      it 'does not overwrite given parameters' do
        hash = notifier.send(:generate_message, { host: 'test.example.com' })
        expect(hash[:host]).to eq 'test.example.com'
      end
    end
  end

  describe 'add' do
    def unpack_message(datagrams)
      deserialized_message = Zlib::Inflate.inflate(datagrams[0])
      Oj.load(deserialized_message)
    end

    it 'sends a simple message' do
      expect(sender).to receive(:send)
      notifier.info('test')
    end

    it 'does not log message below severity' do
      notifier.level = Logger::ERROR

      expect(sender).to_not receive(:send)
      notifier.debug('test')
    end

    it 'sends a proper packet' do
      # We expect the message serializer to work because we have tests
      # for it already.  Instead only test a simple message.

      expect(sender).to receive(:send) do |datagrams|
        message = unpack_message(datagrams)
        expect(message['short_message']).to eq('test')
      end

      notifier.debug('test')
    end

    it 'defaults to unknown severity' do
      expect(sender).to receive(:send) do |datagrams|
        message = unpack_message(datagrams)
        expect(message['level']).to eq(Logger::UNKNOWN)
      end

      notifier.add(nil, 'test')
    end

    it 'uses block to get message if no message given' do
      expect(sender).to receive(:send) do |datagrams|
        message = unpack_message(datagrams)
        expect(message['short_message']).to eq('test')
      end

      notifier.add(Logger::INFO) do
        'test'
      end
    end
  end
end
