
# Server side for RPC calls. 
#
class Zack::Server
  class SimpleFactory < Struct.new(:implementation_klass)
    def produce; implementation_klass.new; end
  end
  
  attr_reader :tube_name
  
  def initialize(tube_name, opts={})
    server = opts[:server] || 'beanstalk:11300'
    
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
    rq_id, sym, args, answer_tube = nil, nil, nil, nil
    begin
      rq_id, sym, args, answer_tube = YAML.load(job.body)
    ensure
      # If yaml decoding crashes, the message is probably invalid. Delete it. 
      # If an exception is raised later on, we treat the request as satisfied.
      job.delete
    end
    
    instance = @factory.produce
    retval = instance.send(sym, *args)
    
    if answer_tube
      on_tube(answer_tube) do
        @connection.put [rq_id, retval].to_yaml
      end
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
  
private
  def on_tube(temporary_tube_name)
    begin
      @connection.use temporary_tube_name
      
      yield
    ensure
      @connection.use @tube_name
    end
  end
end