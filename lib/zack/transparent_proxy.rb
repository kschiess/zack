
require 'timeout'

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
      timeout(@timeout || 1) do
        return service.call([sym, args])
      end
    else
      service.notify [sym, args]
      return nil
    end
  rescue Timeout::Error => ex
    puts ex.backtrace
    
    raise Zack::ServiceTimeout, "The service took too long to answer (>#{@timeout || 1}s)."
  end
end