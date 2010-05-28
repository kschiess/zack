
# Server side for RPC calls. 
#
class Zack::Server
  def initialize(tube_name, opts={})
    server = opts[:server] || 'localhost:11300'
    
    @factory = opts[:factory]

    unless @factory
      raise ArgumentError, "Either :factory or :implementation argument must be given." 
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