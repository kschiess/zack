require 'spec_helper'

describe Zack::Notifier do
  class Handler
    def initialize(backchannel)
      @backchannel = backchannel
    end
    def pids
      backchannel << Process.pid
    end
  end

  let(:backchannel) { Cod.pipe }
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
          factory: lambda { Handler.new(backchannel) },
          server: 'localhost:11300').run
      end
    }
  }
  # Makes sure the server processes are killed. 
  after(:each) { 
    @pids.each do |pid|
      Process.kill('TERM', pid)
    end
    Process.waitall
  }

  it "returns all return values from all listeners" do
    notifier.pids
    
    while backchannel.waiting?
      @pids.should include(backchannel.get)
    end
  end
end

