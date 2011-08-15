require 'uuid'

# A UUID based unique name based on base_name. 
#
class Zack::UniqueName
  def initialize(base_name)
    @name = unique_tube_name(base_name)
  end
  
  attr_reader :name
  
  alias to_s name

private
  # Pretend that UUIDs don't collide for now.
  #
  def unique_tube_name(name)
    "name.#{uuid}"
  end
  def uuid
    uuid_generator.generate
  end
  def uuid_generator
    generator=Thread.current[:zack_uuid_generator]
    return generator if generator
  
    # assert: generator is nil
  
    # Pretend we've just forked, because that might be the case. 
    UUID.generator.next_sequence
  
    Thread.current[:zack_uuid_generator]=generator=UUID.new
  end
  
end