# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{zack}
  s.version = "0.3.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kaspar Schiess", "Patrick Marchi"]
  s.date = %q{2011-08-31}
  s.email = ["kaspar.schiess@absurd.li", "mail@patrickmarchi.ch"]
  s.extra_rdoc_files = ["README"]
  s.files = ["History.txt", "LICENSE", "Rakefile", "README"] +
    Dir.glob("{lib,spec,example}/**/*")
  s.homepage = %q{http://github.com/kschiess/zack}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Ruby RPC calls via Cod}
  
  s.add_runtime_dependency('cod', "~> 0.4")
  s.add_runtime_dependency('uuid', '~> 2.3')

  s.add_development_dependency('beanstalk-client', ["~> 1.0"])
end
