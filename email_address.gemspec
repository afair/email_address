lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "email_address/version"

Gem::Specification.new do |spec|
  spec.name = "email_address"
  spec.version = EmailAddress::VERSION
  spec.authors = ["Allen Fair"]
  spec.email = ["allen.fair@gmail.com"]
  spec.description = "The EmailAddress Gem to work with and validate email addresses."
  spec.summary = "This gem provides a ruby language library for working with and validating email addresses. By default, it validates against conventional usage, the format preferred for user email addresses. It can be configured to validate against RFC “Standard” formats, common email service provider formats, and perform DNS validation."
  spec.homepage = "https://github.com/afair/email_address"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 2.5", "< 4"
  spec.files = `git ls-files`.split($/)
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest", "~> 5.11"
  spec.add_development_dependency "bundler" # ,      "~> 1.16.0"
  if RUBY_PLATFORM == "java"
    spec.add_development_dependency "activerecord", "~> 7.2.0"
    spec.add_development_dependency "activerecord-jdbcsqlite3-adapter", "~> 70.2"
  else
    spec.add_development_dependency "activerecord", "~> 8.0.0"
    spec.add_development_dependency "sqlite3", "~> 2.1"
    spec.add_development_dependency "standard"
  end
  spec.add_development_dependency "net-smtp"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "bigdecimal"
  spec.add_development_dependency "mutex_m"
  spec.add_development_dependency "irb"

  spec.add_dependency "base64"
  spec.add_dependency "simpleidn"
end
