
require 'zack'

RSpec.configure do |config|
  config.mock_with :flexmock
end

BEANSTALK_CONNECTION = 'localhost:11300'