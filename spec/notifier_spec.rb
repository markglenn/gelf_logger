require 'spec_helper'

describe GelfLogger::Notifier do
  let( :notifier ){ GelfLogger::Notifier.new }

  describe 'generate_message' do
    let( :hash ){ notifier.send( :generate_message, 'Hello World' ) }

    it 'sets version to default' do
      expect( hash[ :version ] ).to eq GelfLogger::SPEC_VERSION
    end

    it 'sets host' do
      expect( hash[ :host ] ).to eq Socket.gethostname
    end

    it 'sets the timestamp' do
      now = Time.now.utc.to_f
      expect( ( hash[ :timestamp ] - now ).abs ).to be <= 1
    end

    context 'string' do
      it 'sets short message' do
        expect( hash[ :short_message ] ).to eq 'Hello World'
      end
    end

    context 'hash' do
      let( :hash ){ notifier.send( :generate_message, { hello: 'world' } ) }

      it 'uses given hash' do
        expect( hash[ :hello ] ).to eq 'world'
      end

      it 'does not overwrite given parameters' do
        hash = notifier.send( :generate_message, { host: 'test.example.com' } )
        expect( hash[ :host ] ).to eq 'test.example.com'
      end
    end
  end

end
