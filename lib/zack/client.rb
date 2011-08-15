

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
    #
    def initialize(tube_name, opts={})
      server = opts[:server] || 'beanstalk:11300'
      # Only respond to these messages
      @only        = opts[:only] || proc { true }
      # These have answers (wait for the server to answer)
      @with_answer = opts[:with_answer] || []

      @outgoing = Cod.beanstalk(server, tube_name)
      unless @with_answer.empty?
        @incoming = Cod.beanstalk(server, 
          UniqueName.new(tube_name))
      end
    
      @service = Cod::Client.new(@outgoing, @incoming, 1)
    end
  
    def respond_to?(msg)
      !! @only[msg]
    end

    def has_answer?(sym)
      @with_answer.include?(sym.to_sym)
    end

    include TransparentProxy
  end
end