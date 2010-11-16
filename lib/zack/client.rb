
require 'digest/md5' # ruby 1.9

# Client part of Zack RPC
#
class Zack::Client  
  def initialize(tube_name, opts={})
    server = opts[:server] || 'beanstalk:11300'
    
    @connection = Beanstalk::Connection.new(server, tube_name)

    @with_answer = opts[:with_answer] || []
    @timeout     = opts[:timeout] || 10 # seconds
    
    unless @with_answer.empty?
      # Ain't it beautiful
      digest = Digest::MD5.new
      digest << @connection.instance_variable_get('@socket').addr.to_s

      @answer_queue_name = "answer_"+digest.hexdigest
      @answer_connection = Beanstalk::Connection.new(server, @answer_queue_name)
    end
  end
  
  def respond_to?(msg)
    true
  end
  def method_missing(sym, *args, &block)
    raise ArgumentError, "Can't call methods remotely with a block" if block
    
    message = create_message(sym, args)
    @connection.put message.serialize

    if message.has_answer?
      loop do
        answer = read_next_answer
        
        # Discard answers that don't match our request
        return answer.value if message.answered_by?(answer)
      end
    end
    
    return nil
  end
  
private
  # Create a Zack::Message from a method call. 
  #
  def create_message(sym, args)
    # We allow for @answer_queue_name to be nil sometimes!
    Zack::Message.new(generate_request_id, sym, args, @answer_queue_name)
  end

  # Retrieves the next answer from the answer queue and deletes it there. 
  #
  def read_next_answer
    begin
      job = @answer_connection.reserve(@timeout)
    rescue Beanstalk::TimedOut
      raise Zack::ServiceTimeout.new("Timed out after #{@timeout} seconds waiting for an answer from the service")
    end

    job.delete
    return Zack::Answer.deserialize(job.body)
  end

  # Generates a request id. 
  #
  def generate_request_id
    @__request_id ||= 0
    @__request_id += 1
  end
end