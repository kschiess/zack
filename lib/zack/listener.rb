
module Zack
  # Receives messages emitted by Notifier. The pub/sub pattern implemented 
  # by these two classes corresponds to Cod::Topic and Cod::Directory.
  #
  class Listener < Target
    attr_reader :service
  
    def initialize(tube_name, opts={})
      super
        
      channel = Cod.beanstalk(server, tube_name)
      answer_channel = Cod.beanstalk(server, 
        UniqueName.new(tube_name))
        
      @service = Cod::Topic.new('', channel, answer_channel)
    end
  
    # Handles exactly one request. 
    #
    def handle_request
      sym, args = service.get
      process_request sym, args
    end
  end
end