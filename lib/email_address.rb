require "email_address/version"
require "email_address/config"
require "email_address/host"
require "email_address/esp"
require "email_address/exchanger"
require "email_address/local"
require "email_address/validator"
require 'simpleidn'

module EmailAddress

  def new(address)
    EmailAddress::Address.new(address)
  end

end
