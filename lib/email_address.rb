require "email_address/address"
require "email_address/config"
require "email_address/domain_matcher"
require "email_address/domain_parser"
require "email_address/exchanger"
require "email_address/host"
require "email_address/local"
require "email_address/validator"
require "email_address/version"
require "email_address/active_record_validator" if defined?(ActiveModel)

module EmailAddress

  def self.new(email_address)
    EmailAddress::Address.new(email_address)
  end
end
