require 'spec_helper'
require 'oj'

describe GelfLogger::Notifier do
  let(:notifier) { GelfLogger::Notifier.new('test.example.com', 123) }
  let(:sender) { GelfLogger::Sender.new('test.example.com', 123) }

  before do
    notifier.sender = sender
  end

  describe 'generate_message' do
    let(:hash) { notifier.send(:generate_message, 'Hello World', Logger::INFO) }

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
      let(:hash) { notifier.send(:generate_message, { short_message: 'world' }, Logger::INFO) }

      it 'uses given hash' do
        expect(hash[:short_message]).to eq 'world'
      end

      it 'does not overwrite given parameters' do
        hash = notifier.send(:generate_message, { host: 'test.example.com' }, Logger::INFO)
        expect(hash[:host]).to eq 'test.example.com'
      end

      it 'handles unknown keys by adding underscore' do
        hash = notifier.send(:generate_message, { line: 123 }, Logger::INFO)
        expect(hash[:_line]).to eq 123
      end

      it 'does not modify known keys' do
        hash = notifier.send(
          :generate_message,
          {
            short_message: 'My message',
            full_message: 'Full message'
          },
          Logger::INFO
        )

        GelfLogger::Notifier::VALID_GELF_KEYS.each do |key|
          expect(hash[key.to_sym]).to_not be_nil
        end
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

      notifier.info { 'test' }
    end

    it 'sets progname to facility if not given' do
      expect(sender).to receive(:send) do |datagrams|
        message = unpack_message(datagrams)
        expect(message['_facility']).to eq('my-program')
      end

      notifier.default_options[:facility] = 'my-program'
      notifier.info 'test'
    end

    it 'uses hash if given' do
      expect(sender).to receive(:send) do |datagrams|
        message = unpack_message(datagrams)
        expect(message['short_message']).to eq('Hello World')
        expect(message['full_message']).to eq('This is a test')
      end

      notifier.info do
        {
          short_message: 'Hello World',
          full_message: 'This is a test'
        }
      end
    end
  end

  describe 'max_chunk_size=' do
    it 'sets chunk size to 1420 when set to wan' do
      notifier.max_chunk_size = 'wan'
      expect(notifier.max_chunk_size).to eq 1420
    end

    it 'sets chunk size to 8154 when set to lan' do
      notifier.max_chunk_size = 'lan'
      expect(notifier.max_chunk_size).to eq 8154
    end

    it 'sets chunk size to value given' do
      notifier.max_chunk_size = 123
      expect(notifier.max_chunk_size).to eq 123
    end
  end
end
