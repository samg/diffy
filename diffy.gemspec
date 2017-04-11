# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'diffy/version'

Gem::Specification.new do |spec|
  spec.name          = "diffy"
  spec.version       = Diffy::VERSION
  spec.authors       = ["Sam Goldstein"]
  spec.email         = ["sgrock@gmail.org"]
  spec.description   = "Convenient diffing in ruby"
  spec.summary       = "A convenient way to diff string in ruby"
  spec.homepage      = "http://github.com/samg/diffy"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", '>= 3.4.4'

  spec.requirements << 'posix-spawn, if not Windows & Not jruby'

  spec.post_install_message = "Thanks for installing! Please make sure to add posix-spawn as dependency if NON-Windows OS & Not jruby"
end
