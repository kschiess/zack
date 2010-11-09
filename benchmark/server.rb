
$:.unshift 'lib'
require 'zack'

$requests = 0

class Foo
  def foo
    $requests += 1
    puts $requests
    return 42
  end
end

Zack::Server.new(
  'benchmark', 
  :server => 'localhost:11300', 
  :simple => Foo).run