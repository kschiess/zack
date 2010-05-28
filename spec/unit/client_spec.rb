
require 'spec_helper'

describe Zack::Client do
  let(:beanstalk) { Beanstalk::Connection.new(BEANSTALK_CONNECTION, 'zack_client_test') }
  
  let(:client) { Zack::Client.new('zack_client_test') }
  
  # Retrieves one message from the queue and decodes it. 
  def receive_message
    message = beanstalk.reserve(1)
    YAML.load(message.body)
  end
  
  context "when calling #foobar(123, '123', :a123)" do
    before(:each) { client.foobar(123, '123', :a123) }
    
    it "should queue the message [:foobar, [123, '123', :a123]]" do
      receive_message.should == [:foobar, [123, '123', :a123]]
    end 
  end
end