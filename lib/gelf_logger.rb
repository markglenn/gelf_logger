require "gelf_logger/version"
require 'gelf_logger/notifier'
require 'gelf_logger/message_serializer'

module GelfLogger
  SPEC_VERSION = '1.1'
  MAX_DATAGRAM_SIZE = 8192
end
