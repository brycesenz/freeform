# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'freeform/version'

Gem::Specification.new do |spec|
  spec.name = "freeform"
  spec.version = Freeform::VERSION
  spec.authors = ["brycesenz"]
  spec.email = ["bryce.senz@gmail.com"]
  spec.description = %q{Decouple your forms from your domain models}
  spec.summary = %q{FreeForm lets you compose forms however you like, explicitly guiding how each field maps back to your domain models. No more accepting nested attributes!}
  spec.homepage = "https://github.com/brycesenz/freeform"
  spec.license = "MIT"

  spec.files = `git ls-files`.split($/)
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel"
  spec.add_dependency "simple_form"
  spec.add_dependency "formtastic"
  spec.add_dependency "nested_form", "~> 0.3.2"
  spec.add_dependency "rails", "~> 3.2.0"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-rails", "~> 2.6"
end

