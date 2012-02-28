require 'rake/clean'
require "rubygems"
require 'rubygems/package_task'

require 'rspec'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new
task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new

# This task actually builds the gem. 
task :gem => :spec
spec = eval(File.read('zack.gemspec'))

desc "Generate the gem package."
Gem::PackageTask.new(spec)

CLEAN << 'doc'
CLEAN << 'pkg'
