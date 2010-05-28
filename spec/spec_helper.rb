
require 'zack'

Spec::Runner.configure do |config|
  config.mock_with :flexmock
end

BEANSTALK_CONNECTION = 'localhost:11300'