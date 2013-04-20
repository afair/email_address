require "email_address/version"
require "email_address/host"
require "email_address/address"

module EmailAddress

  def self.new(address)
    EmailAddress::Address.new(address)
  end
end
