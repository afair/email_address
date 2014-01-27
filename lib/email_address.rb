require "email_address/address"
require "email_address/config"
require "email_address/domain_matcher"
require "email_address/domain_parser"
require "email_address/esp"
require "email_address/exchanger"
require "email_address/host"
require "email_address/local"
require "email_address/validator"
require "email_address/version"

module EmailAddress

  def self.new(address)
    EmailAddress::Address.new(address)
  end

end
