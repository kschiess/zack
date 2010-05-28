
# Client part of Zack RPC
#
class Zack::Client
  def initialize(tube_name, opts={})
    server = opts[:server] || 'localhost:11300'
    
    @connection = Beanstalk::Connection.new(server, tube_name)
  end
  
  def respond_to?(msg)
    true
  end
  def method_missing(sym, *args, &result_callback)
    @connection.put [sym, args].to_yaml
  end
end