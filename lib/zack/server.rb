
module Zack
  # Server side for RPC calls. 
  #
  class Server < Target
    attr_reader :service
  
    def initialize(tube_name, opts={})
      super
        
      channel = Cod.beanstalk(tube_name, server)
      @service = Cod::Service.new(channel)
    end
  
    # Handles exactly one request. 
    #
    def handle_request
      service.one { |(sym, args)|  
        process_request(sym, args)
      }
    end
  end
end