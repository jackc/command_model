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

  gem.add_dependency 'activemodel', "> 3.2"

  gem.add_development_dependency 'rake', "~> 10.1.0"
  gem.add_development_dependency 'rspec', "~> 2.11.0"
  gem.add_development_dependency 'guard', "~> 1.5.3"
  gem.add_development_dependency 'guard-rspec', "~> 2.1.1"
  gem.add_development_dependency 'rb-fsevent', '~> 0.9.1'

end
