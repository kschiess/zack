require 'spec_helper'

describe "Server#run" do
  class RunServerRun
    def crash
      raise "Some Exception"
    end
    def message
      # ...
    end
  end
  
  # Isolates the specs by clearing the 'server_run' tube before use.
  before(:each) { 
    conn = Beanstalk::Connection.new(BEANSTALK_CONNECTION, 'server_run')
    
    while conn.peek_ready
      conn.reserve.delete
    end
    
    conn.close
  }
  
  let(:server) { Zack::Server.new(
    'server_run', 
    :simple => RunServerRun,
    :server => BEANSTALK_CONNECTION) 
  }
  let(:client) { Zack::Client.new(
    'server_run', :server => BEANSTALK_CONNECTION) 
  }

  it "should loop forever" do
    flexmock(server).should_receive(:loop).and_yield
    
    # Post a message for the server to handle
    client.message
    
    # Run just once
    server.run
  end
    
  context "when given a block" do
    it "should yield exceptions" do
      flexmock(server).should_receive(:loop).and_yield
      client.crash    # this will raise an exception as soon as we run
      
      called = false
      server.run { |exception|
        called = true
        exception.should be_a(RuntimeError)
        exception.message.should == "Some Exception"
      }
      
      called.should == true
    end
  end
end