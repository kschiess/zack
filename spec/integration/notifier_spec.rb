require 'spec_helper'

describe Zack::Notifier do
  class Handler
    def initialize(backchannel)
      @backchannel = backchannel
    end
    def pids
      @backchannel.put Process.pid
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
      backchannel_dup = backchannel.dup
      fork do
        listener = Zack::Listener.new(
          'football', 
          factory: lambda { Handler.new(backchannel_dup) },
          server: 'localhost:11300')
        
        backchannel_dup.put :ready
        listener.run
      end
    }
    @pids.size.times { backchannel.get }
  }
  # Makes sure the server processes are killed. 
  after(:each) { 
    @pids.each do |pid|
      Process.kill('TERM', pid)
    end
    Process.waitall
  }

  it "executes all registered listeners" do
    notifier.pids
    
    resulting_pids = @pids.size.times.map { backchannel.get(timeout: 0.5) }
    
    resulting_pids.should =~ @pids
  end
end

