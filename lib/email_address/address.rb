module EmailAddress

  class Address
    attr_reader :address, :mailbox, :account, :host, :tags

    def initialize(address)
      self.address = address
    end

    def address=(address)
      (@mailbox, host) = address.strip.split(/\@/)
      return unless host
      @host = EmailAddress::Host.new(host)
      address.downcase!
      @address = address
      
      if address =~ /\A(.+?)\+(.+)\z/
        @account = $1
        @tags = $2
      else
        @account = @address
        @tags = ""
      end
      # @account = @host.esp.unique_account(@account)

      @address
    end

    def valid?
      return false unless valid_format?
      true
    end

    def valid_format?
      return false unless @mailbox =~ /\A[\w\.\-\+\']+\z/
      return false unless @host.valid?
      true
    end
    
  end
end
