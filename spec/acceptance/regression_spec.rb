require 'spec_helper'

require 'timeout'

describe "Regression: " do
  def self.fork_server(server_class)
    # Fork a server in the background
    before(:each) { 
      # Clear old messages
      conn = Beanstalk::Connection.new(BEANSTALK_CONNECTION, 'regression')
      while conn.peek_ready
        conn.reserve.delete
      end
      
      # Start a new server
      @pid = fork do
        $stderr.reopen('/dev/null')
        Zack::Server.new(
          'regression', 
          :server => BEANSTALK_CONNECTION, 
          :simple => server_class
        ).run
      end
    }
    after(:each) { 
      Process.kill('KILL', @pid) 
      Process.waitpid(@pid)
    }
  end
  def get_client(timeout, *with_answer)
    Zack::Client.new(
      'regression', 
      :timeout => timeout,
      :server => BEANSTALK_CONNECTION, 
      :with_answer => with_answer)
  end

  def print_stats
    connection = Beanstalk::Connection.new(BEANSTALK_CONNECTION)

    puts "Stats: "
    pp connection.stats

    puts "Tubes: "
    connection.list_tubes.each do |tube|
      p tube
      pp connection.stats_tube(tube)
    end
    
    connection.close
  end
    
  describe "asynchronous long running message, followed by a short running reader message (bug)" do
    class Regression1Server
      def reader; 42; end
      def long_running; sleep 0.1 end
    end
    fork_server Regression1Server

    let(:client) { get_client(10, :reader) }

    # Wait for the server to launch
    before(:each) { 
      sleep 0.01    # This is the same bug that we expose below...
      # wait till the server works
      client.reader.should == 42
    }
  
    it "should correctly call the reader" do
      # Because the code used to watch ALL tubes, not just the relevant ones, 
      # we got our own request back from the service tube when waiting for an
      # answer on the answer tube. 
      client.long_running
      client.reader.should == 42
    end 
  end
  describe "server crash during a message that has an answer" do
    class CrashingServer
      def crash_and_burn
        fail
      end
    end
    
    fork_server CrashingServer
    let(:client) { get_client(1, :crash_and_burn) }
    
    RSpec::Matchers.define :take_long do 
      match(&lambda do |block|
        begin 
          Timeout::timeout(2) do
            block.call
          end
        rescue Timeout::Error
          return true
        end
        false
      end)
    end
    
    it "should timeout a blocking call" do
      lambda {
        lambda {
          client.crash_and_burn
        }.should_not take_long
      }.should raise_error(Zack::ServiceTimeout)
    end
  end
  describe "server that takes a long time, timeout in client stops the operation" do
    class LongRunningServer
      def long_running(time, answer)
        sleep time
        return answer
      end
    end
    
    fork_server LongRunningServer
    let(:client) { get_client(1, :long_running) }
    
    it "should pass a sanity check" do
      client.long_running(0, 42).should == 42
    end 
    context "message ordering" do
      before(:each) {
        begin
          client.long_running(1.1, 10)
        rescue Zack::ServiceTimeout
        end
      }
      
      it "should be preserved" do
        client.long_running(0, 42).should == 42
      end
    end
  end
end