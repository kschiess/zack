require 'yaml'

class Zack::Message < Struct.new(:id, :sym, :args, :queue)
  
  # Serialize this message for the wire. 
  #
  def serialize
    [id, sym, args, queue].to_yaml
  end
  
  # Create a new message from the wire. 
  #
  def self.deserialize(str)
    new *YAML.load(str)
  end
  
  # Returns true if an answer queue has been set. As it happens, that field
  # is only set when the message should wait for an answer. 
  #
  def needs_answer?
    !! queue
  end
  
  # Could the answer given be an answer to this message? 
  #
  def answered_by?(answer)
    answer.id == self.id
  end
  
  # Deliver this message to +object+. 
  #
  def deliver_to(object)
    retval = object.send(sym, *args)
    
    Zack::Answer.new(id, retval)
  end
end