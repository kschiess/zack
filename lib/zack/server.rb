
module Zack
  # Server side for RPC calls. 
  #
  class Server
    attr_reader :service
    attr_reader :factory
    attr_reader :server
    
    # Initializes a zack server. To specify which class should be the target
    # of the RPC call, you must either give the :factory or the :simple
    # argument. 
    #
    # Note that in any case, one object instance _per call_ is created. This
    # is to discourage creating stateful servers. 
    #
    # @param tube_name [String] the tube to communicate with
    # @option opts [Class] :simple class will be constructed for each request.
    #   The request will then be handed to the class.
    # @option opts [#call] :factory factory for request handler instances. One
    #   parameter gets passed to this call, the control structure for the 
    #   beanstalk connection.
    #   
    def initialize(tube_name, opts={})
      @server = opts[:server]
      @tube_name = tube_name

      if opts.has_key? :factory
        @factory = opts[:factory]
      elsif opts.has_key? :simple
        klass = opts[:simple]
        @factory = lambda { |ctl| klass.new }
      else
        raise ArgumentError, "Either :factory or :simple argument must be given." 
      end

      reconnect
    end 
   
    # Handles exactly one request. 
    # @private
    #
    def handle_request(exception_handler=nil)
      service.one { |(sym, args), control|
        exception_handling(exception_handler, control) do
          # p [sym, args]
          process_request(control, sym, args)
        end
      }
      
    # Reconnect when the connection is lost  
    rescue Cod::ConnectionLost
      @channel.close
      reconnect
      
      retry 
    end
    
    # Processes exactly one request, but doesn't define how the request gets
    # here. 
    # @private
    #
    def process_request(control, sym, args)
      instance = factory.call(control)

      instance.send(sym, *args)
    end

    # Runs the server and keeps running until the world ends (or the process,
    # whichever comes first). If you pass a non-nil messages argument, the
    # server will process that many messages and then quit. (Maybe you will
    # want to respawn the server from time to time?)
    #
    # Any exception that is raised inside the RPC code will be passed to the
    # exception_handler block: 
    # 
    #   server.run do |exception, control|
    #     # control is the service control object from cod. You can exercise
    #     # fine grained message control using this. 
    #     log.fatal exception
    #   end
    #
    # If you don't reraise exceptions from the exception handler block, they
    # will be caught and the server will stay running. 
    #
    # @param messages [Number] how many messages to process, or nil for endless
    #   operation
    # @yield [Exception, Cod::Beanstalk::Service::Control]
    #
    def run(messages=nil, &exception_handler)
      loop do
        handle_request(exception_handler)

        if messages
          messages -= 1
          break if messages <= 0
        end
      end
    end

    # Closes the connection and shuts down the server. 
    #
    def close
      @channel.close
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

    def reconnect
      @channel = Cod.beanstalk(@tube_name, @server)
      @service = @channel.service
    end
  end
end