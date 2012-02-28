# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{zack}
  s.version = "0.3.4"

  s.authors = ["Kaspar Schiess", "Patrick Marchi"]
  s.email = ["kaspar.schiess@absurd.li", "mail@patrickmarchi.ch"]

  s.extra_rdoc_files = ["README"]
  s.rdoc_options = ["--main", "README"]

  s.files = ["History.txt", "LICENSE", "Rakefile", "README"] +
    Dir.glob("{lib,spec,example}/**/*")

  s.homepage = %q{http://github.com/kschiess/zack}

  s.require_paths = ["lib"]

  s.summary = %q{Ruby RPC calls via Cod}
  
  s.add_runtime_dependency('cod', "~> 0.4.3")
  s.add_runtime_dependency('uuid', '~> 2.3')

  s.add_development_dependency('beanstalk-client', ["~> 1.0"])
  s.add_development_dependency('rake')

  s.add_development_dependency('rspec')
  s.add_development_dependency('flexmock')

  s.add_development_dependency('guard')
  s.add_development_dependency('guard-rspec')
  s.add_development_dependency('growl')
  s.add_development_dependency('rb-fsevent')
  
  s.add_development_dependency('yard')
end
