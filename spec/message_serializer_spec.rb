require 'spec_helper'

describe GelfLogger::MessageSerializer do
  let(:serializer) { GelfLogger::MessageSerializer.new }

  describe 'deflate_message' do
    it 'deflates the message' do
      message = { hello: 'world' }

      result = serializer.deflate_message(message)
      deserialized_message = Zlib::Inflate.inflate(result.to_a.pack('C*'))
      expect(Oj.dump(message, mode: :compat)).to eq(deserialized_message)
    end
  end

  describe 'chunk_bytes' do
    it 'does not split short data' do
      result = serializer.chunk_bytes('abc'.bytes)
      expect(result.count).to eq 1
      expect(result[ 0 ]).to eq 'abc'
    end

    it 'splits large messages' do
      result = serializer.chunk_bytes(('a' * (GelfLogger::MAX_DATAGRAM_SIZE + 1)).bytes)
      expect(result.count).to eq 2

      expect(result[0][12..-1]).to eq 'a' * GelfLogger::MAX_DATAGRAM_SIZE
      expect(result[1][12..-1]).to eq 'a'

      # Sets the GELF magic bytes
      expect(result[0][0..1]).to eq "\x1e\x0f"
      expect(result[1][0..1]).to eq "\x1e\x0f"

      # Sets the message ID
      expect(result[0][2..9]).to eq result[1][2..9]

      # Sets the sequence number
      expect(result[0][10]).to eq "\x00"
      expect(result[1][10]).to eq "\x01"

      # Sets the sequence count
      expect(result[0][11]).to eq "\x02"
      expect(result[1][11]).to eq "\x02"
    end
  end
end
