# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'diffy/version'

Gem::Specification.new do |spec|
  spec.name          = "ydiffy"
  spec.version       = Diffy::VERSION
  spec.authors       = ["Sam Goldstein"]
  spec.email         = ["sgrock@gmail.org"]
  spec.description   = "Convenient diffing in ruby"
  spec.summary       = "Ydiffy is a fork of diffy to work around a problem in odba"
  spec.homepage      = "http://github.com/zdavatz/ydiffy"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
