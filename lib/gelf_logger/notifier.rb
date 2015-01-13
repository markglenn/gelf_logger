require 'oj'

module GelfLogger
  class Notifier
    attr_accessor :default_options

    MAX_DATAGRAM_SIZE = 8192

    def initialize
      @default_options = {
        version: SPEC_VERSION,
        host: Socket.gethostname
      }
    end

  private

    def generate_message( object )
      hash = if object.respond_to? :to_hash
               object.to_hash
             else
               { short_message: object }
             end

      hash = @default_options.merge( hash )
      hash[ :timestamp ] ||= Time.now.utc.to_f

      hash
    end
  end
end
