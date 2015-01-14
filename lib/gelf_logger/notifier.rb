require 'oj'
require 'logger'

module GelfLogger
  class Notifier < Logger
    attr_accessor :message_serializer
    attr_accessor :level
    attr_accessor :sender

    attr_reader :default_options
    attr_reader :max_chunk_size

    VALID_GELF_KEYS = %w(version host short_message full_message timestamp level)

    SEVERITY_MAP = {
      DEBUG   => 0,
      INFO    => 1,
      WARN    => 2,
      ERROR   => 3,
      FATAL   => 4,
      UNKNOWN => 5
    }

    WAN_CHUNK_SIZE = 1420
    LAN_CHUNK_SIZE = 8154

    def initialize(host, port, default_options = {})
      @default_options = {
        version: SPEC_VERSION,
        host: Socket.gethostname
      }.merge( default_options )

      @message_serializer = MessageSerializer.new
      @sender = Sender.new(host, port)
      @level = DEBUG
    end

    def add(severity, message = nil, progname = nil)
      severity ||= UNKNOWN
      return true if severity < @level

      if message.nil?
        if block_given?
          message = yield
        else
          message, progname = progname, nil
        end
      end

      send_message(message, progname, severity)
    end

    def send_message(message, progname, severity)
      message = generate_message(message, SEVERITY_MAP[severity])
      message[:_facility] ||= progname

      datagrams = @message_serializer.chunk_bytes(
        @message_serializer.deflate_message(message)
      )
      sender.send(datagrams)

      true
    end

    def max_chunk_size=(size)
      @max_chunk_size =
        case size.to_s.downcase
        when 'wan'
          WAN_CHUNK_SIZE
        when 'lan'
          LAN_CHUNK_SIZE
        else
          size.to_int
        end
    end

    private

    def generate_message(object, severity)
      hash = if object.respond_to? :to_hash
               object.to_hash
             else
               { short_message: object }
             end

      hash = @default_options.merge(hash)
      hash[:timestamp] ||= Time.now.utc.to_f
      hash[:level] ||= severity

      fix_keys!(hash)

      hash
    end

    def fix_keys!(hash)
      hash.keys.each do |key|
        unless VALID_GELF_KEYS.include?(key.to_s)
          hash[('_' + key.to_s).to_sym] = hash.delete(key)
        end
      end
    end
  end
end
