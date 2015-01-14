require 'spec_helper'

describe GelfLogger::Sender do
  describe 'send' do
    let(:socket){ instance_double('UDPSocket') }
    let(:sender){ GelfLogger::Sender.new('test.example.com', 12345, socket) }

    it 'sends a single packet' do
      expect(socket).to receive(:send).with('test', 'test.example.com', 12345)

      sender.send(['test'])
    end

    it 'sends multiple packets' do
      expect(socket).to receive(:send).with('hello', 'test.example.com', 12345)
      expect(socket).to receive(:send).with('world', 'test.example.com', 12345)

      sender.send(%w(hello world))
    end
  end
end
