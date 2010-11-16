require 'autotest/rspec2'

class Autotest::Rspec2 < Autotest
  def setup_rspec_project_mappings
    add_mapping(%r%^spec/unit/.*_spec\.rb$%) { |filename, _|
      filename
    }
    add_mapping(%r%^lib/(.*)\.rb$%) { |_, m|
      ["spec/unit/#{m[1]}_spec.rb"]
    }
  end
end

Autotest.add_discovery { "rspec2" }