require 'spec_helper'

describe "Exception handling" do
  # Clear old messages (test isolation)
  before(:each) { 
    conn = Beanstalk::Connection.new(BEANSTALK_CONNECTION, 'exceptions')
    while conn.peek_ready
      conn.reserve.delete
    end
    conn.close
  }
  
  SimpleService = Struct.new(:control, :retry_log) do
    # Used for the exception block specs
    def do_something
      fail
    end

    # Used for the handler specs
    def retry_message
      retries = (retry_log[control.msg_id] += 1)
      if retries < 2
        control.retry
      end
    end
  end
  
  let!(:retry_log) { Hash.new(0) }
  
  let(:client) { Zack::Client.new('exceptions', 
    server: BEANSTALK_CONNECTION) }
  let(:server) { Zack::Server.new('exceptions', 
    server: BEANSTALK_CONNECTION, 
    factory: proc { |c| SimpleService.new(c, retry_log) }) }
  
  describe 'block given to #run' do
    it "can retry the message" do
      client.do_something
      
      retried = false
      server.run(2) do |exception, control|
        retried ? control.delete : control.retry
        retried = true
      end
            
      retried.should == true
    end
    it "can use msg_id to retry n times" do
      client.do_something
      client.do_something
      
      retry_per_msg = Hash.new(0)
      
      server.run(4) do |exception, control|
        retries = (retry_per_msg[control.msg_id] += 1)
        retries < 2 ? control.retry : control.delete
      end
            
      retry_per_msg.should have(2).messages
      retry_per_msg.each do |msg_id, retries|
        msg_id.should >0
        retries.should == 2
      end
    end 
  end
  describe 'using the control parameter to the factory' do
    it "can retry the message from within the handler" do
      client.retry_message
      server.run(2)
      
      retry_log.should have(1).message
      
      msg_id, retries = retry_log.first
      msg_id.should > 0
      retries.should == 2
    end 
  end
end