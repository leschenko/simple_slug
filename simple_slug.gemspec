# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'simple_slug/version'

Gem::Specification.new do |spec|
  spec.name          = 'simple_slug'
  spec.version       = SimpleSlug::VERSION
  spec.authors       = ['Alex Leschenko']
  spec.email         = ['leschenko.al@gmail.com']
  spec.summary       = %q{Simple slug generator with history.}
  spec.description   = %q{This is not a "bulldozer. This is just friendly id generator fo ActiveRecord."}
  spec.homepage      = 'https://github.com/leschenko/simple_slug'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '~> 4.0.0'
  spec.add_dependency 'i18n', '~> 0.6.0'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
