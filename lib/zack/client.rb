
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
  def method_missing(sym, *args, &result_callback)
    request_id = generate_request_id
    message = [request_id, sym, args]
    
    if @with_answer.include? sym
      message << @answer_queue_name
    end
    
    @connection.put message.to_yaml

    if @with_answer.include? sym      
      loop do
        answer_id, answer = get_next_answer
        return answer if answer_id == request_id
      end
    end
    
    return nil
  end
  
private
  # Retrieves the next answer from the answer queue and deletes it there. 
  #
  def get_next_answer
    begin
      job = @answer_connection.reserve(@timeout)
    rescue Beanstalk::TimedOut
      raise Zack::ServiceTimeout.new("Timed out after #{@timeout} seconds waiting for an answer from the service")
    end

    job.delete
    return YAML.load(job.body)
  end

  # Generates a request id. 
  #
  def generate_request_id
    @__request_id ||= 0
    @__request_id += 1
  end
end