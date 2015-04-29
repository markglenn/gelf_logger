require 'atomic'
require 'json'

module GelfLogger
  class MessageSerializer
    class << self; attr_accessor :last_message_id; end
    @last_message_id = Atomic.new(0)

    def deflate_message(message)
      Zlib::Deflate.deflate(JSON.dump(message)).bytes
    end

    def chunk_bytes(data)
      if data.count <= GelfLogger::MAX_DATAGRAM_SIZE
        [data.to_a.pack('C*')]
      else
        split_data(data)
      end
    end

    private

    def split_data(data)
      datagrams = []
      message_id = updated_message_id

      sequence_count = (data.count / GelfLogger::MAX_DATAGRAM_SIZE.to_f).ceil
      sequence_number = 0

      data.each_slice(GelfLogger::MAX_DATAGRAM_SIZE) do |slice|
        datagrams << "\x1e\x0f" + message_id + [sequence_number, sequence_count, *slice].pack('C*')
        sequence_number += 1
      end

      datagrams
    end

    def updated_message_id
      message_id = MessageSerializer.last_message_id.update { |i| i + 1 }
      Digest::MD5.digest("#{Time.now.to_f}#{message_id}")[0, 8]
    end
  end
end
