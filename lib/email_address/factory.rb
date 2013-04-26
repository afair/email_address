module EmailAddress

  # EmailAddress::Address - Inspects a Email Address.
  #
  # Format: mailbox@hostname
  #
  class Factory
    attr_reader :mailbox, :host

    def address(address)
      (@mailbox, host) = address.strip.split(/\@/)
      return unless host
      @host = EmailAddress::Host.new(host)
      @mailbox = @host.provider_address(@mailbox)
    end
  end
end
