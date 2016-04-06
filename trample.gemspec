# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trample/version'

Gem::Specification.new do |spec|
  spec.name          = "trample"
  spec.version       = Trample::VERSION
  spec.authors       = ["richmolj"]
  spec.email         = ["richmolj@gmail.com"]

  spec.summary       = %q{Abstraction on top of searchkick to handle form inputs easily}
  spec.description   = spec.summary
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'virtus', '~> 1.0'
  spec.add_dependency 'searchkick', '~> 1.0'

  spec.add_development_dependency "activerecord", "~> 4.0"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
end
