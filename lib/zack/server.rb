
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
        @factory = lambda { |ctl| klass.new }
      else
        raise ArgumentError, "Either :factory or :simple argument must be given." 
      end
 
      channel = Cod.beanstalk(tube_name, server)
      @service = channel.service
    end 
   
    # Handles exactly one request. 
    #
    def handle_request(exception_handler=nil)
      service.one { |(sym, args), control|
        exception_handling(exception_handler, control) do
          process_request(control, sym, args)
        end
      }
    end
    
    # Processes exactly one request, but doesn't define how the request gets
    # here. 
    #
    def process_request(control, sym, args)
      instance = factory.call(control)

      instance.send(sym, *args)
    end

    # Runs the server and keeps running until the world ends (or the process, 
    # whichever comes first).
    #
    def run(&exception_handler)
      loop do
        handle_request(exception_handler)
      end
    end

  private
    # Defines how the server handles exception. 
    #
    def exception_handling(exception_handler, control)
      begin
        yield
      rescue => exception
        # If we have an exception handler, it gets handed all the exceptions. 
        # No exceptions stop the operation. 
        if exception_handler
          exception_handler.call(exception, control)
        else
          raise
        end
      end
    end
  end
end