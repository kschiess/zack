module Zack
  class Notifier
    attr_reader :service
    
    DirectoryNotifier = Struct.new(:directory) do
      def notify(message)
        # Publish with an empty string. We don't use the match_expr of topic
        # here much yet, but that might change: I can imagine doing something
        # like this: 
        #
        #   notifier.topic('foo').flabbergast(1)
        #
        directory.publish('', message)
      end
    end
    
    def initialize(tube_name, opts={})
      server = opts[:server] || 'beanstalk:11300'
      
      channel = Cod.beanstalk(server, tube_name)
      @service = DirectoryNotifier.new(
        Cod::Directory.new(channel))
    end

    def respond_to?(sym)
      true
    end
    
    def has_answer?(sym)
      false
    end
    
    include TransparentProxy
  end
end