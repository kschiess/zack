

# Client part of Zack RPC
#
class Zack::Client
  attr_reader :service
  
  def initialize(tube_name, opts={})
    server = opts[:server] || 'beanstalk:11300'
    # Only respond to these messages
    @only        = opts[:only] || proc { true }
    # These have answers (wait for the server to answer)
    @with_answer = opts[:with_answer] || []

    @outgoing = Cod.beanstalk(server, tube_name)
    unless @with_answer.empty?
      @incoming = Cod.beanstalk(server)
    end
    
    @service = Cod::Client.new(@outgoing, @incoming, 1)
  end
  
  def respond_to?(msg)
    !! @only[msg]
  end
  def method_missing(sym, *args, &block)
    super unless respond_to?(sym)
    
    raise ArgumentError, "Can't call methods remotely with a block" if block

    if has_answer?(sym)
      return service.call([sym, args])
    else
      service.notify [sym, args]
      return nil
    end
  rescue Cod::Channel::TimeoutError
    raise Zack::ServiceTimeout, "No response from server in the allowed time."
  end
  
  def has_answer?(sym)
    @with_answer.include?(sym.to_sym)
  end
end