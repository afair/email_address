
module EmailAddress
  CHECK_CONVENTIONAL_SYNTAX = 1 # Real-word Conventional Syntax
  CHECK_STANDARD_SYNTAX     = 2 # RFC-Compliant Syntax
  CHECK_PROVIDER_SYNTAX     = 3 # Syntax rules by email provider
  CHECK_DNS                 = 4 # Perform DNS A-Record ookup on domain
  CHECK_MX                  = 5 # Perform DNS MX-Record lookup on domain
  CHECK_CONNECT             = 6 # Attempt connection to remote mail server
  CHECK_SMTP                = 7 # Perform SMTP email verification

  SYSTEM_MAILBOXES = %w(abuse help mailer-daemon postmaster root)
  ROLE_MAILBOXES   = %w(info sales staff office marketing orders billing
                        careers jobs)

require "email_address/address"
require "email_address/config"
require "email_address/domain_matcher"
require "email_address/domain_parser"
require "email_address/exchanger"
require "email_address/host"
require "email_address/local"
require "email_address/matcher"
require "email_address/validator"
require "email_address/version"
require "email_address/active_record_validator" if defined?(ActiveModel)
if defined?(ActiveRecord) && ::ActiveRecord::VERSION::MAJOR >= 5
  require "email_address/email_address_type"
  require "email_address/canonical_email_address_type"
end

  # Creates an instance of this email address.
  # This is a short-cut to Email::Address::Address.new
  def self.new(email_address)
    EmailAddress::Address.new(email_address)
  end

  # Given an email address, this return true if the email validates, false otherwise
  def self.valid?(email_address, options={})
    self.new(email_address).valid?(options)
  end

  # Shortcut to normalize the given email address
  def self.normal(email_address)
    EmailAddress::Address.new(email_address).normalize
  end

  def self.new_normal(email_address)
    EmailAddress::Address.new(EmailAddress::Address.new(email_address).normalize)
  end

  # Returns the Canonical form of the email address. This form is what should
  # be considered unique for an email account, lower case, and no address tags.
  def self.canonical(email_address)
    EmailAddress::Address.new(email_address).canonical
  end

  def self.new_canonical(email_address)
    EmailAddress::Address.new(EmailAddress::Address.new(email_address).canonical)
  end

  # Returns the Reference form of the email address, defined as the MD5
  # digest of the Canonical form.
  def self.reference(email_address)
    EmailAddress::Address.new(email_address).reference
  end
end
