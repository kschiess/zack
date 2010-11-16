require 'yaml'

class Zack::Message < Struct.new(:id, :sym, :args, :queue)
  
  # Serialize this message for the wire. 
  #
  def serialize
    [id, sym, args, queue].to_yaml
  end
  
  # Returns true if an answer queue has been set. As it happens, that field
  # is only set when the message should wait for an answer. 
  #
  def has_answer?
    !! queue
  end
  
  def answered_by?(answer)
    answer.id == self.id
  end
end