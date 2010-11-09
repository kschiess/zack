
$:.unshift 'lib'
require 'zack'

foo = Zack::Client.new('benchmark', :server => 'localhost:11300', 
  :with_answer => [:foo])

10000.times do |i|
  result = nil
  begin
    result = foo.foo
  rescue
    puts i+1
    raise
  end

  if result != 42
    puts "Incorrect: #{result.inspect}"
  end
end
