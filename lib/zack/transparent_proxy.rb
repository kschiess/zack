
# A method missing implementation that will use respond_to? to see wether a 
# message should be answered. If yes, it delegates the message to service, 
# which is supposed to return one of Cods RPC client primitives. Depending on
# the value of has_answer?(symbol), either #call or #notify is used. 
#
module Zack::TransparentProxy
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
end