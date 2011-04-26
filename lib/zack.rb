
require 'cod'

module Zack
  autoload :Server, 'zack/server'
  autoload :Client, 'zack/client'
  
  # Gets raised when the server doesn't answer within the currently configured
  # timeout for a message that waits for an answer. 
  #
  class ServiceTimeout < StandardError; end
end
