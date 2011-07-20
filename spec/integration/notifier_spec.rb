require 'spec_helper'

describe Zack::Notifier do
  class Handler
    def pids
      Process.pid
    end
    def shutdown
      exit 0
    end
  end
  
  let(:notifier) {
    Zack::Notifier.new(
      'football', 
      server: 'localhost:11300', 
      with_answer: [:bar])
  }

  # Starts two server processes that are notified of events. 
  before(:each) { 
    @pids = 2.times.map { 
      fork do
        Zack::Listener.new(
          'football', 
          simple: Handler,
          server: 'localhost:11300').run
      end
    }
  }
  # Makes sure the server processes are killed. 
  after(:each) { 
    notifier.shutdown
    
    @pids.each do |pid|
      Process.kill('TERM', pid)
    end
    Process.waitall
  }

  it "returns all return values from all listeners" do
    notifier.pids =~ @pids
  end
end

