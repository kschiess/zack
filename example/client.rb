$:.unshift File.dirname(__FILE__) + "/../lib"
require 'zack'

client = Zack::Client.new('sample', 
  :with_answer => [:get_time])

client.announce
puts client.get_time