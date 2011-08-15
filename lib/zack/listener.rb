
module Zack
  # Server side for RPC calls. 
  #
  class Listener
    attr_reader :service
  
    def initialize(tube_name, opts={})
      server = opts[:server] || 'beanstalk:11300'
    
      if opts.has_key? :factory
        @factory = opts[:factory]
      elsif opts.has_key? :simple
        klass = opts[:simple]
        @factory = lambda { klass.new }
      else
        raise ArgumentError, "Either :factory or :simple argument must be given." 
      end
        
      channel = Cod.beanstalk(server, tube_name)
      answer_channel = Cod.beanstalk(server, 
        UniqueName.new(tube_name))
      @service = Cod::Topic.new('', channel, answer_channel)
    end
  
    # Handles exactly one request. 
    #
    def handle_request
      sym, args = service.get
      
      instance = @factory.call
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