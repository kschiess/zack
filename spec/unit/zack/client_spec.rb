
require 'spec_helper'

describe Zack::Client do
  let(:beanstalk) { Beanstalk::Connection.new(BEANSTALK_CONNECTION, 'zack_client_test') }
  before(:each) do
    while beanstalk.peek_ready
      beanstalk.reserve.delete
    end
  end
  
  context "when not waiting for answers" do
    let(:client) { Zack::Client.new(
      'zack_client_test', 
      :server => BEANSTALK_CONNECTION, 
      :only   => { :foo => true, :foobar => true }, 
      :with_answer => [:bar]) }

    # Replace Cod with a mock
    let(:service) { flexmock(:service) }
    before(:each) { flexmock(client).should_receive(:service).and_return(service) }
    
    describe "return value for asynchronous calls" do
      it "should be nil" do
        service.should_receive(:notify)
        
        client.foo.should be_nil
      end 
    end
    describe "calling rpc method with a block" do
      it "should raise ArgumentError" do
        lambda {
          client.foo { something }
        }.should raise_error(ArgumentError)
      end 
    end
    context "when calling #foobar(123, '123', :a123)" do
      it "should queue the message [:foobar, [123, '123', :a123]]" do
        service.should_receive(:notify).with([:foobar, [123, '123', :a123]]).once
        
        client.foobar(123, '123', :a123)
      end 
    end
  end
end