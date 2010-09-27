
require 'spec_helper'

describe Zack::Client do
  let(:beanstalk) { Beanstalk::Connection.new(BEANSTALK_CONNECTION, 'zack_client_test') }
  before(:each) do
    while beanstalk.peek_ready
      beanstalk.reserve.delete
    end
  end
  
  # Retrieves one message from the queue and decodes it. 
  def receive_message
    message = beanstalk.reserve(1)
    message.delete
    YAML.load(message.body)
  end

  context "when not waiting for answers" do
    let(:client) { Zack::Client.new(
      'zack_client_test', 
      :server => BEANSTALK_CONNECTION) }

    describe "return value" do
      subject { client.foo }
      it { should be_nil }
    end
    context "when calling #foobar(123, '123', :a123)" do
      before(:each) { client.foobar(123, '123', :a123) }

      it "should queue the message [:foobar, [123, '123', :a123]]" do
        receive_message.should == [:foobar, [123, '123', :a123]]
      end 
    end
  end
  context ":with_answer option" do
    let(:client) { Zack::Client.new(
      'zack_client_test', 
      :with_answer => [:foo], 
      :server => BEANSTALK_CONNECTION) }
    
    context "when calling foo" do
      attr_reader :answer

      # Sends the server a message (as YAML)
      def send_answer(answer, answer_queue)
        beanstalk.use answer_queue
        beanstalk.put answer.to_yaml
      end

      def wait_for_answer
        timeout(1) do
          loop do
            break if @done
            sleep 0.05
          end
        end
      end

      before(:each) do
        @done = false
        Thread.start do 
          @answer = client.foo
          @done = true
        end
      end

      it "should queue the message [:foo, [], 'answer_queue']" do
        sym, args, answer_queue = receive_message
        begin
          sym.should == :foo
          args.should == []
          answer_queue.should match(/answer_.*/)
        ensure
          # Make sure the client will receive an answer.
          send_answer('', answer_queue)
        end
      end

      context "when the answer is posted" do
        attr_reader :answer_queue
        before(:each) do
          sym, args, @answer_queue = receive_message
          send_answer('blah', answer_queue)
          wait_for_answer
        end
        
        subject { answer }
        it { should == 'blah' }

        it "should delete the job on the answer queue" do
          stat = beanstalk.stats_tube(answer_queue)
          stat['current-jobs-urgent'].should == 0
          stat['current-jobs-ready'].should == 0
          stat['current-jobs-reserved'].should == 0
          stat['current-jobs-delayed'].should == 0
          stat['current-jobs-buried'].should == 0
        end
      end
    end
  end
end