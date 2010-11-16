require 'spec_helper'

describe Zack::Answer do
  it "should construct with an id and a value" do
    Zack::Answer.new(23, 'some_value')
  end
  
  context "instance (23, 'some_value')" do
    let(:answer) { Zack::Answer.new(23, 'some_value') }

    it "should deserialize from yaml" do
      Zack::Answer.deserialize(
        answer.serialize)
    end 
  end
  
end