require 'spec_helper'

describe Zack::Server do
  context "when constructing without :factory / :implementation" do
    it "should raise ArgumentError" do
      lambda {
        Zack::Server.new('foobar')
      }.should raise_error(ArgumentError)
    end
  end
end

describe Zack::Server, 'with a factory' do
  # A small factory that always returns instance.
  class ImplFactory < Struct.new(:instance)
    def produce
      instance
    end
  end
  
  let(:beanstalk) { Beanstalk::Connection.new(BEANSTALK_CONNECTION, 'zack_server_test') }
  let(:implementation) { flexmock(:implementation) }
  let(:server) {
    Zack::Server.new(
      'zack_server_test', 
      :factory => ImplFactory.new(implementation), 
      :server => BEANSTALK_CONNECTION
    )
  }

  subject { server }
  
  # Sends the server a message (as YAML)
  def send_message(message)
    beanstalk.put message.to_yaml
  end

  describe "<- #handle_request" do
    context "when receiving [:foobar, [123, '123', :a123]]" do
      before(:each) { send_message([:foobar, [123, '123', :a123]]) }
      after(:each) { server.handle_request }
      
      it "should call the right message on implementation" do
        implementation.
          should_receive(:foobar).
          with(123, '123', :a123).
          once
      end 
    end
  end
end