require 'spec_helper'

describe "Regression: " do
  describe "asynchronous long running message, followed by a short running reader message (bug)" do
    class Regression1Server
      def reader; 42; end
      def long_running; sleep 0.1 end
    end
    
    # Fork a server in the background
    before(:each) { 
      @pid = fork do
        Zack::Server.new(
          'regression_1', 
          :server => BEANSTALK_CONNECTION, 
          :simple => Regression1Server
        ).run
      end
    }
    after(:each) { 
      Process.kill('TERM', @pid) 
    }

    let(:client) { Zack::Client.new(
      'regression_1', 
      :server => BEANSTALK_CONNECTION, 
      :with_answer => [:reader]) 
    }

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
end