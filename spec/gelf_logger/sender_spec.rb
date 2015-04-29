require 'spec_helper'

describe GelfLogger::Sender do
  describe 'send' do
    let(:socket) { instance_double('UDPSocket') }
    let(:sender) { GelfLogger::Sender.new('test.example.com', 123, socket) }

    it 'sends a single packet' do
      expect(socket).to receive(:send).with('test', 0, 'test.example.com', 123)

      sender.send(['test'])
    end

    it 'sends multiple packets' do
      expect(socket).to receive(:send).with('hello', 0, 'test.example.com', 123)
      expect(socket).to receive(:send).with('world', 0, 'test.example.com', 123)

      sender.send(%w(hello world))
    end
  end
end
