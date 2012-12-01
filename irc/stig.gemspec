# -*- encoding: utf-8; mode: ruby -*-
require File.expand_path('../lib/stig/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["mtgto"]
  gem.email         = ["hogerappa@gmail.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "stig"
  gem.require_paths = ["lib"]
  gem.version       = Stig::VERSION

  gem.add_dependency "net-irc", "~> 0.0.9"
end
