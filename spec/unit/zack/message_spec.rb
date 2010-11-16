require 'spec_helper'

describe Zack::Message do
  it "should construct with 3 arguments" do
    Zack::Message.new(1, :message, [:arg1, :arg2])
  end 
  it "should construct with 4 arguments" do
    Zack::Message.new(1, :message, [:arg1, :arg2], 'answer_queue_123234343')
  end
  
  context "sample instance (with answer)" do
    let(:message) { Zack::Message.new(1, :message, [:arg1, :arg2], 'answer_queue_123234343') }
    subject { message }

    describe "<- #serialize" do
      it "should emit the message array" do
        message.serialize.should == "--- \n- 1\n- :message\n- - :arg1\n  - :arg2\n- answer_queue_123234343\n"
      end 
    end 
    describe "<- #has_answer?" do
      subject { message.has_answer? }
      
      it { should == true }
    end
    describe "<- #answered_by?(answer)" do
      subject { message.answered_by?(answer) }

      context "answer id 1" do
        let(:answer) { flexmock(:id => 1) }
        
        it { should == true}
      end
      context "answer id other than 1" do
        let(:answer) { flexmock(:id => 323) }
        
        it { should == false}
      end
    end
  end
  
end