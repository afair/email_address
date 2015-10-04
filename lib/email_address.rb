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

module EmailAddress

  # Creates an instance of this email address.
  # This is a short-cut to Email::Address::Address.new
  def self.new(email_address)
    EmailAddress::Address.new(email_address)
  end

  # Given an email address, this return true if the email validates, false otherwise
  def self.valid?(email_address, options={})
    self.new(email_address).valid?(options)
  end
end
