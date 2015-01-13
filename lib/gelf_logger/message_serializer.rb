require 'atomic'

module GelfLogger
  class MessageSerializer
    @@last_message_id = Atomic.new( 0 )

    def deflate_message( message )
      Zlib::Deflate.deflate( Oj.dump( message, mode: :compat ) ).bytes
    end

    def chunk_bytes( data )
      datagrams = []

      if data.count <= GelfLogger::Notifier::MAX_DATAGRAM_SIZE
        datagrams << data.to_a.pack( 'C*' )
      else
        message_id = Digest::MD5.digest(
          "#{Time.now.to_f}#{@@last_message_id.update{|i| i + 1}}"
        )[0, 8]

        sequence_count = ( data.count / GelfLogger::Notifier::MAX_DATAGRAM_SIZE.to_f ).ceil
        sequence_number = 0

        data.each_slice( GelfLogger::Notifier::MAX_DATAGRAM_SIZE ) do |slice|
          datagrams << "\x1e\x0f" + message_id + [ sequence_number, sequence_count, *slice ].pack( 'C*' )
          sequence_number += 1
        end
      end

      datagrams
    end
  end
end
