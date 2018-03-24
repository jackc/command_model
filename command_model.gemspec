# -*- encoding: utf-8 -*-
require File.expand_path('../lib/command_model/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jack Christensen"]
  gem.email         = ["jack@jackchristensen.com"]
  gem.description   = %q{CommandModel - when update_attributes isn't enough.}
  gem.summary       = %q{CommandModel integrates Rails validations with command objects. This allows errors from command execution to easily be handled with the familiar Rails validation system.}
  gem.homepage      = "https://github.com/JackC/command_model"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "command_model"
  gem.require_paths = ["lib"]
  gem.version       = CommandModel::VERSION

  gem.required_ruby_version = '>= 2.5.0'

  gem.add_dependency 'activemodel', "> 4.2"

  gem.add_development_dependency 'rake', "~> 12.3.0"
  gem.add_development_dependency 'rspec', "~> 3.7.0"
end
