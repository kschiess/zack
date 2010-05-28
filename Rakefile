require 'spec'
require 'spec/rake/spectask'

Spec::Rake::SpecTask.new

task :default => :spec

Spec::Runner.configure do |config|
  config.mock_with :flexmock
end
