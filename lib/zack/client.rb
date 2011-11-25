

module Zack
  # Client for a simple client-server RPC connection. 
  #
  class Client
    attr_reader :service

    # Constructs a client for the service given by tube_name. Optional
    # arguments are: 
    #
    # :server :: beanstalkd server location url
    # :only :: ignores all messages not in this hash
    # :with_answer :: these messages wait for an answer from the service
    # :timeout :: How long to wait for an answer
    #
    def initialize(tube_name, opts={})
      # Only respond to these messages
      @only        = opts[:only] || proc { true }
      # These have answers (wait for the server to answer)
      @with_answer = opts[:with_answer] || []
      @timeout     = opts[:timeout]
      
      @tube_name  = tube_name
      @server     = opts[:server] || 'localhost:11300'

      connect
    end
  
    def respond_to?(msg)
      !! @only[msg]
    end

    def has_answer?(sym)
      @with_answer.include?(sym.to_sym)
    end

    def method_missing(sym, *args, &block)
      super unless respond_to?(sym)

      raise ArgumentError, "Can't call methods remotely with a block" if block

      if has_answer?(sym)
        with_timeout do
          return service.call([sym, args])
        end
      else
        service.notify [sym, args]
        return nil
      end
    rescue Timeout::Error => ex
      raise Zack::ServiceTimeout, "The service took too long to answer (>#{@timeout || 1}s)."
    end

  private 
    def with_timeout
      if @timeout
        begin
          timeout(@timeout) do
            yield
          end
        rescue Timeout::Error 
          # The timeout might have occurred at any place at all. This means
          # that the connection is probably in an invalid state at this point. 
          reconnect
          raise Zack::ServiceTimeout, 
            "The server took longer than #{@timeout} seconds to respond."
        end
      else
        yield
      end
    end
    
    def reconnect
      @service.close
      connect
    end
    def connect
      @outgoing = Cod.beanstalk(@tube_name, @server)

      unless @with_answer.empty?
        @incoming = Cod.beanstalk(
          UniqueName.new(@tube_name), 
          @server)
      end
    
      @service = Cod::Service::Client.new(@outgoing, @incoming)
    end
  end
end