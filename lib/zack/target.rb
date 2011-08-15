
module Zack
  # Abstract base class for everything that is an RPC target. This implements
  # some common mechanisms like a run loop, exception handling and argument
  # handling. 
  #
  class Target
    attr_reader :factory
    attr_reader :server
    
    # Initializes #factory and #server.
    #
    def initialize(tube_name, opts={})
      @server = opts[:server] || 'beanstalk:11300'

      if opts.has_key? :factory
        @factory = opts[:factory]
      elsif opts.has_key? :simple
        klass = opts[:simple]
        @factory = lambda { klass.new }
      else
        raise ArgumentError, "Either :factory or :simple argument must be given." 
      end
    end

    # Processes exactly one request, but doesn't define how the request gets
    # here. 
    #
    def process_request(sym, args)
      instance = factory.call
      
      instance.send(sym, *args)
    end
    
    # Handles one request. This is specific to implementors. 
    #
    def handle_request
      raise NotImplementedError, 
        "Abstract base class doesn't implement #handle_request."
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