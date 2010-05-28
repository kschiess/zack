
# Server side for RPC calls. 
#
class Zack::Server
  class SimpleFactory < Struct.new(:implementation_klass)
    def produce; implementation_klass.new; end
  end
  
  def initialize(tube_name, opts={})
    server = opts[:server] || 'localhost:11300'
    
    if opts.has_key? :factory
      @factory = opts[:factory]
    elsif opts.has_key? :simple
      @factory = SimpleFactory.new(opts[:simple])
    else
      raise ArgumentError, "Either :factory or :simple argument must be given." 
    end
        
    @connection = Beanstalk::Connection.new(server, tube_name)
  end
  
  def handle_request
    job = @connection.reserve
    begin
      sym, args = YAML.load(job.body)
      
      instance = @factory.produce
      instance.send(sym, *args)
    ensure
      job.delete
    end
  end
end