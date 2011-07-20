
require 'cod'

module Zack
  # Gets raised when the server doesn't answer within the currently configured
  # timeout for a message that waits for an answer. 
  #
  class ServiceTimeout < StandardError; end
end

require 'zack/server'
require 'zack/client'
require 'zack/notifier'
