require 'spec_helper'

require 'tcp_proxy'

describe "Connection interruption:" do
  # Clear old messages (test isolation)
  before(:each) { 
    conn = Beanstalk::Connection.new(BEANSTALK_CONNECTION, 'reconnect')
    while conn.peek_ready
      conn.reserve.delete
    end
    conn.close
  }

  class SimpleFlagServer
    def signal
      @signalled = true
    end
    
    def clear
      @signalled = false
    end
    
    def signalled?
      @signalled
    end
  end
  
  def sub_port(connstr, new_port)
    parts = BEANSTALK_CONNECTION.split(':')
    parts[1] = new_port
    parts.join(':')
  end

  let(:flag_server) { SimpleFlagServer.new }
  let(:client) { Zack::Client.new('reconnect', server: BEANSTALK_CONNECTION) }
  let(:server) { Zack::Server.new('reconnect', 
    server: BEANSTALK_CONNECTION, 
    factory: proc { |c| flag_server }) }
        
  after(:each) { client.close; server.close }

  it "smoke test to verify the setup" do
    client.signal
    server.run(1)
    
    flag_server.should be_signalled
  end
  
  describe 'when the connection between the client and the beanstalkd server disappears' do
    let!(:proxy) { TCPProxy.new('localhost', 11301, 11300) }
    after(:each) { proxy.close }
    
    let(:client) { Zack::Client.new('reconnect', 
      server: sub_port(BEANSTALK_CONNECTION, 11301)) }
    
    # Try out the connection before interrupting it  
    before(:each) { 
      client.signal
      server.run(1)

      flag_server.should be_signalled
      flag_server.clear
    }
    
    it "reconnects automatically" do
      proxy.drop_all
      
      expect {
        client.signal
      }.to raise_error(Zack::AnswerLost)
      
      # The client should have reconnected, so this should now work: 
      client.signal
      server.run(1)

      flag_server.should be_signalled
    end 
  end
  describe 'when the connection between the server and the beanstalkd server disappears' do
    let!(:proxy) { TCPProxy.new('localhost', 11301, 11300) }
    after(:each) { proxy.close }
    
    let(:server) { Zack::Server.new('reconnect', 
      server: sub_port(BEANSTALK_CONNECTION, 11301), 
      factory: proc { |c| flag_server }) }
    
    # Try out the connection before interrupting it  
    before(:each) { 
      client.signal
      server.run(1)

      flag_server.should be_signalled

      flag_server.clear
    }
    
    it "reconnects automatically" do
      # Post one message to the queue
      client.signal
      proxy.drop_all

      # Try to process a message (connection is interrupted)
      server.run(1)
      
      flag_server.should be_signalled
    end 
  end
end