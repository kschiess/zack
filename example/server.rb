
require 'zack'

class ChunkyBaconAnnouncer
  def announce
    puts 'chunky bacon'
  end
end

Zack::Server.new('sample', :simple => ChunkyBaconAnnouncer).run