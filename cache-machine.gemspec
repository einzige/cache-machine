# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{cache-machine}
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sergei Zinin", "Kevin Goslar"]
  s.date = %q{2012-03-19}
  s.description = %q{A Ruby on Rails framework to support cache management based on explicitely modeled caching dependencies.}
  s.email = %q{szinin@partyearth.com}
  s.extra_rdoc_files = %w{LICENSE.txt README.md}
  s.files = `git ls-files`.split("\n")
  s.homepage = %q{http://github.com/partyearth/cache-machine}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{A Ruby on Rails framework to support cache management based on explicitely modeled caching dependencies.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>, [">= 3"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.21"])
    else
      s.add_dependency(%q<rails>, [">= 3"])
      s.add_dependency(%q<bundler>, ["~> 1.0.21"])
    end
  else
    s.add_dependency(%q<rails>, [">= 3"])
    s.add_dependency(%q<bundler>, ["~> 1.0.21"])
  end
end
