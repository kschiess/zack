
class Handler
  def foo
    puts "Foo was called."
  end
  def bar
    Process.pid
  end
  def shutdown
    exit 0
  end
end

source = Zack::Notifier.new(
  'football', 
  server: 'localhost:11300', 
  with_answer: [:bar])
  
%w(foo bar).each do |filter|
  fork do
    handler = Zack::Listener.new(
      'football', 
      simple: Handler,
      server: 'localhost:11300')
      
    handler.run
  end
end

source.foo
p source.bar

source.shutdown

Process.waitall