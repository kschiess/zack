require 'spec_helper'

describe "Regression: " do
  def self.fork_server(server_class)
    # Fork a server in the background
    before(:each) { 
      @pid = fork do
        Zack::Server.new(
          'regression', 
          :server => BEANSTALK_CONNECTION, 
          :simple => server_class
        ).run
      end
    }
    after(:each) { 
      Process.kill('TERM', @pid) 
      Process.waitpid(@pid)
    }
  end
  let(:client) { Zack::Client.new(
    'regression', 
    :server => BEANSTALK_CONNECTION, 
    :with_answer => [:reader]) 
  }
    
  describe "asynchronous long running message, followed by a short running reader message (bug)" do
    class Regression1Server
      def reader; 42; end
      def long_running; sleep 0.1 end
    end
    
    fork_server Regression1Server

    # Wait for the server to launch
    before(:each) { 
      sleep 0.01    # This is the same bug that we expose below...
      timeout(1) do
        # wait till the server works
        client.reader.should == 42
      end
    }
  
    it "should correctly call the reader" do
      # Because the code used to watch ALL tubes, not just the relevant ones, 
      # we got our own answer back from the service tube when waiting for an
      # answer on the answer tube. 
      client.long_running
      client.reader.should == 42
    end 
  end
  describe "server crash during a message that has an answer" do
    
  end
end