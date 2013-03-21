# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pandler/version'

Gem::Specification.new do |gem|
  gem.name          = "pandler"
  gem.version       = Pandler::VERSION
  gem.authors       = ["Ryosuke IWANAGA"]
  gem.email         = ["riywo.jp@gmail.com"]
  gem.description   = %q{Mannage your packages on your distribution}
  gem.summary       = %q{Yumfile}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'thor', '>= 0.13.6'
  gem.add_dependency 'fpm'

  gem.add_development_dependency 'rake', '>= 0.9.2.2'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'webmock'
end
