require "email_address/version"
require "email_address/config"
require "email_address/host"
require "email_address/address"

module EmailAddress

  def self.new(address)
    #EmailAddress::Address.new(address)
    (mailbox, host) = address.strip.split(/\@/)
    return unless host
    host = EmailAddress::Host.new(host)
    address = host.address(mailbox)
  end
end
