
require 'digest/md5' # ruby 1.9

# Client part of Zack RPC
#
class Zack::Client
  def initialize(tube_name, opts={})
    server = opts[:server] || 'localhost:11300'
    
    @connection = Beanstalk::Connection.new(server, tube_name)

    @with_answer = opts[:with_answer] || []
    unless @with_answer.empty?
      # Ain't it beautiful
      digest = Digest::MD5.new
      digest << @connection.instance_variable_get('@socket').addr.to_s
      @answer_queue_name = "answer_"+digest.hexdigest
      @connection.watch @answer_queue_name
    end
  end
  
  def respond_to?(msg)
    true
  end
  def method_missing(sym, *args, &result_callback)
    message = [sym, args]
    
    if @with_answer.include? sym
      message << @answer_queue_name
    end
    
    @connection.put message.to_yaml

    if @with_answer.include? sym
      answer = @connection.reserve
      return YAML.load(answer.body)
    end
    
    return nil
  end
end