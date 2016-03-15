# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'multiconnect/version'

Gem::Specification.new do |spec|
  spec.name          = "multiconnect"
  spec.version       = Multiconnect::VERSION
  spec.authors       = ["Greg Orlov"]
  spec.email         = ["gaorlov@gmail.com"]

  spec.summary       = %q{Allows a client to try several methods of fetching data with fallbacks}
  spec.description   = %q{Allows a client to try several methods of fetching data with fallbacks}
  spec.homepage      = "https://github.com/gaorlov/multiconnect"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "m"
  spec.add_development_dependency "simplecov"

end
