# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'has_s3_attachment/version'

Gem::Specification.new do |spec|
  spec.name          = "has_s3_attachment"
  spec.version       = HasS3Attachment::VERSION
  spec.authors       = ["Pavlo Osadchyi"]
  spec.email         = ["posadchiy@gmail.com"]

  spec.summary       = %q{Gently wraps you s3 resource urls into ActiveModel::Record}
  spec.description   = %q{Gently wraps you s3 resource urls into ActiveModel::Record}
  spec.homepage      = "http://github.com/pavloo/has_s3_attachment"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.2.0"
  spec.add_development_dependency "webmock", "~> 1.21.0"

  spec.add_runtime_dependency "aws-sdk", "~> 2"
end
