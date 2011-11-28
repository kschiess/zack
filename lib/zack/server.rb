
module Zack
  # Server side for RPC calls. 
  #
  class Server
    attr_reader :service
    attr_reader :factory
    attr_reader :server
    
    def initialize(tube_name, opts={})
      @server = opts[:server]

      if opts.has_key? :factory
        @factory = opts[:factory]
      elsif opts.has_key? :simple
        klass = opts[:simple]
        @factory = lambda { klass.new }
      else
        raise ArgumentError, "Either :factory or :simple argument must be given." 
      end
 
      channel = Cod.beanstalk(tube_name, server)
      @service = channel.service
    end 
   
    # Handles exactly one request. 
    #
    def handle_request
      service.one { |(sym, args)|  
        process_request(sym, args)
      }
    end
    
    # Processes exactly one request, but doesn't define how the request gets
    # here. 
    #
    def process_request(sym, args)
      instance = factory.call

      instance.send(sym, *args)
    end

    # Runs the server and keeps running until the world ends (or the process, 
    # whichever comes first).
    #
    def run(&block)
      loop do
        exception_handling(block) do
          handle_request
        end
      end
    end

  private
    # Defines how the server handles exception. 
    #
    def exception_handling(exception_handler)
      if exception_handler
        begin
          yield
        rescue => exception
          exception_handler.call(exception)
        end
      else
        yield
      end
    end
  
  end
end