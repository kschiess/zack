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
    let(:implementation) { flexmock(:implementation) }

    # Replacing the Cod::Service with a mock
    let(:service) { flexmock(:service) }
    before(:each) { flexmock(server, :service => service) }

    context "with a factory" do
      # A small factory that always returns instance.
      class ImplFactory < Struct.new(:instance)
        def call
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
      
      describe "<- #handle_request" do
        context "when receiving [:foobar, [123, '123', :a123]]" do
          after(:each) { server.handle_request }

          it "should call the right message on implementation" do
            service.should_receive(:one).
              and_yield([:foobar, [123, '123', :a123]])
            
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

      describe "<- #handle_request" do
        context "when receiving [1, :foobar, [123, '123', :a123]]" do
          after(:each) { server.handle_request }

          it "should call the right message on implementation" do
            service.should_receive(:one).
              and_yield([:foobar, [123, '123', :a123]])
            
            implementation.
              should_receive(:foobar).
              with(123, '123', :a123).
              once
          end 
        end
      end
    end    
  end
end