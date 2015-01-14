require 'oj'
require 'logger'

module GelfLogger
  class Notifier < Logger
    attr_accessor :default_options
    attr_accessor :message_serializer
    attr_accessor :level
    attr_accessor :sender

    SEVERITY_MAP = {
      DEBUG   => 0,
      INFO    => 1,
      WARN    => 2,
      ERROR   => 3,
      FATAL   => 4,
      UNKNOWN => 5
    }

    def initialize(host, port)
      @default_options = {
        version: SPEC_VERSION,
        host: Socket.gethostname
      }

      @message_serializer = MessageSerializer.new
      @sender = Sender.new(host, port)
      @level = DEBUG
    end

    def add(severity, message = nil, progname = nil, &block)
      severity ||= UNKNOWN

      return true if severity < @level

      if message.nil?
        if block_given?
          message = yield
        else
          message = progname
          progname = nil
        end
      end

      message = generate_message({
        short_message: message,
        level: SEVERITY_MAP[severity]
      })

      bytes = @message_serializer.deflate_message(message)
      datagrams = @message_serializer.chunk_bytes(bytes)
      sender.send(datagrams)

      true
    end

  private

    def generate_message(object)
      hash = if object.respond_to? :to_hash
               object.to_hash
             else
               { short_message: object }
             end

      hash = @default_options.merge(hash)
      hash[:timestamp] ||= Time.now.utc.to_f

      hash
    end
  end
end
