require 'spec_helper'

describe Zack::Server do
  context "when constructing without :factory / :simple" do
    it "should raise ArgumentError" do
      lambda {
        Zack::Server.new('foobar')
      }.should raise_error(ArgumentError)
    end
  end
  context "instance" do
    let(:beanstalk) { Beanstalk::Connection.new(BEANSTALK_CONNECTION, 'zack_server_test') }
    let(:implementation) { flexmock(:implementation) }

    # Sends the server a message (as YAML)
    def send_message(message)
      beanstalk.put message.to_yaml
    end

    context "with a factory" do
      # A small factory that always returns instance.
      class ImplFactory < Struct.new(:instance)
        def produce
          instance
        end
      end

      let(:server) {
        Zack::Server.new(
          'zack_server_test', 
          :factory => ImplFactory.new(implementation), 
          :server => BEANSTALK_CONNECTION
        )
      }

      subject { server }

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
    context "with a simple class" do
      let(:implementation_klass) { flexmock(:new => implementation) }
      
      let(:server) {
        Zack::Server.new(
          'zack_server_test', 
          :simple => implementation_klass,
          :server => BEANSTALK_CONNECTION
        )
      }

      subject { server }

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
        context "when receiving [:foobar, [], 'answer_queue']" do
          before(:each) { implementation.should_receive(:foobar => 'blubber') }
          before(:each) { send_message([:foobar, [], 'answer_queue']) }
          before(:each) { server.handle_request }
          
          it "should post the answer to the tube 'answer_queue'" do
            beanstalk.watch 'answer_queue'
            msg = beanstalk.reserve(1)
            msg.delete
            
            YAML.load(msg.body).should == 'blubber'
          end 
        end
      end
    end    
  end
end