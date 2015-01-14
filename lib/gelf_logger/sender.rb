module GelfLogger
  class Sender
    def initialize(host, port, socket = UDPSocket.open)
      @host = host
      @port = port
      @socket = socket
    end

    def send(datagrams)
      datagrams.each do |datagram|
        @socket.send(datagram, @host, @port)
      end
    end
  end
end
