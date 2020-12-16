# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_record_filterable/version'

Gem::Specification.new do |spec|
  spec.name          = 'active_record_filterable'
  spec.version       = ActiveRecord::Filterable::VERSION
  spec.authors       = ['Francisco Padillo']
  spec.email         = ['fpadillo@nosolosoftware.es']
  spec.summary       = 'Easy way to add scopes to your models.'
  spec.description   = 'Easy way to add scopes to your models.'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'sqlite3'
  spec.add_dependency 'activerecord', '>= 3.0'
  spec.add_dependency 'activesupport', '>= 3.0'
end
