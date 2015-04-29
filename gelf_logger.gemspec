# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gelf_logger/version'

Gem::Specification.new do |spec|
  spec.name          = 'gelf_logger'
  spec.version       = GelfLogger::VERSION
  spec.authors       = ['Mark Glenn']
  spec.email         = ['markglenn@gmail.com']
  spec.summary       = 'GELF UDP logger'
  # spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'oj', '~> 2.11'
  spec.add_dependency 'atomic', '~> 1.1'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
end
