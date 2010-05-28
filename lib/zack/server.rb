
# Server side for RPC calls. 
#
class Zack::Server
  class SimpleFactory < Struct.new(:implementation_klass)
    def produce; implementation_klass.new; end
  end
  
  attr_reader :tube_name
  
  def initialize(tube_name, opts={})
    server = opts[:server] || 'localhost:11300'
    
    if opts.has_key? :factory
      @factory = opts[:factory]
    elsif opts.has_key? :simple
      @factory = SimpleFactory.new(opts[:simple])
    else
      raise ArgumentError, "Either :factory or :simple argument must be given." 
    end
        
    @tube_name = tube_name
    @connection = Beanstalk::Connection.new(server, tube_name)
  end
  
  # Handles exactly one request. 
  #
  def handle_request
    job = @connection.reserve
    begin
      sym, args, answer_tube = YAML.load(job.body)
      
      instance = @factory.produce
      retval = instance.send(sym, *args)
      
      if answer_tube
        @connection.use answer_tube
        @connection.put retval.to_yaml
        @connection.use tube_name
      end
    ensure
      job.delete
    end
  end

  # Runs the server and keeps running until the world ends (or the process, 
  # whichever comes first).
  #
  def run
    loop do
      handle_request
    end
  end
end