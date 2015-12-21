# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'email_address/version'

Gem::Specification.new do |spec|
  spec.name          = "email_address"
  spec.version       = EmailAddress::VERSION
  spec.authors       = ["Allen Fair"]
  spec.email         = ["allen.fair@gmail.com"]
  spec.description   = %q{The EmailAddress library is an _opinionated_ email address handler and
validator.}
  spec.summary       = %q{EmailAddress checks on validates an acceptable set of email addresses.}
  spec.homepage      = "https://github.com/afair/email_address"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.8.3"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "activemodel", "~> 5.0.0.beta1"
  spec.add_development_dependency "rake"
  spec.add_dependency "simpleidn"
  spec.add_dependency "netaddr"
end
