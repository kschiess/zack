$:.unshift File.dirname(__FILE__) + "/../lib"
require 'zack'

class ChunkyBaconAnnouncer
  def announce
    puts 'chunky bacon'
  end
  def get_time
    "I wouldn't give you the time"
  end
end

Zack::Server.new(
  'sample', 
  :simple => ChunkyBaconAnnouncer, 
).run