require 'spec_helper'

describe "When beanstalkd disappears" do
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
    
    def signalled?
      @signalled
    end
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
  it "both client and server reconnect" do
  end 
end