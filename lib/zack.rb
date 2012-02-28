
require 'cod'

module Zack
  # Gets raised when the server doesn't answer within the currently configured
  # timeout for a message that waits for an answer. 
  #
  class ServiceTimeout < StandardError; end
  
  # Gets raised when the connection to the beanstalk server is lost during a
  # client call. In some cases you might not loose an answer, but you might
  # have lost the request itself. 
  #
  # The client object reconnects and will work as soon as the beanstalkd
  # server comes back.
  #
  class AnswerLost < StandardError; end
end

require 'zack/unique_name'

require 'zack/server'
require 'zack/client'
