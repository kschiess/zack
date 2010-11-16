# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{zack}
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kaspar Schiess", "Patrick Marchi"]
  s.date = %q{2010-11-15}
  s.email = ["kaspar.schiess@absurd.li", "mail@patrickmarchi.ch"]
  s.extra_rdoc_files = ["README"]
  s.files = ["History.txt", "LICENSE", "Rakefile", "README", "spec", "lib/zack", "lib/zack/client.rb", "lib/zack/server.rb", "lib/zack.rb"]
  s.homepage = %q{http://github.com/kschiess/zack}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Ruby RPC calls via beanstalkd}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<beanstalk-client>, ["~> 1.0.2"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<flexmock>, [">= 0"])
    else
      s.add_dependency(%q<beanstalk-client>, ["~> 1.0.2"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<flexmock>, [">= 0"])
    end
  else
    s.add_dependency(%q<beanstalk-client>, ["~> 1.0.2"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<flexmock>, [">= 0"])
  end
end
