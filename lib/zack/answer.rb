class Zack::Answer < Struct.new(:id, :value)
  # Serialize this message for the wire. 
  #
  def serialize
    [id, value].to_yaml
  end
  
  # Read an answer from the wire format and return a new answer instance. 
  #
  def self.deserialize(str)
    new(*YAML.load(str))
  end
end