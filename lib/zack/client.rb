
require 'uuid'

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
      @incoming = Cod.beanstalk(server, 
        unique_tube_name(tube_name))
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

private 
  # Pretend that UUIDs don't collide for now.
  #
  def unique_tube_name(name)
    "name.#{uuid}"
  end
  def uuid
    uuid_generator.generate
  end
  def uuid_generator
    generator=Thread.current[:zack_uuid_generator]
    return generator if generator
    
    # assert: generator is nil
    
    # Pretend we've just forked, because that might be the case. 
    UUID.generator.next_sequence
    
    Thread.current[:zack_uuid_generator]=generator=UUID.new
  end
end