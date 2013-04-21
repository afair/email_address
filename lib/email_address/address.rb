module EmailAddress

  # EmailAddress::Address - Inspects a Email Address.
  #
  # * hostname - Everything to the rigth of the @
  # * mailbox - Everything to the left of the @
  # * account - part of the mailbox typically sent to a user
  # * tags - Address tags appended to the account for tracking
  #
  class Address
    attr_reader :address, :mailbox, :account, :host, :tags

    def initialize(address)
      self.address = address
    end

    def address=(address)
      (@mailbox, host) = address.strip.split(/\@/)
      return unless host
      @host = EmailAddress::Host.new(host)
      @mailbox.downcase!
      @address = address
      
      if @mailbox =~ /\A(.+?)\+(.+)\z/
        @account = $1
        @tags = $2
      else
        @account = @mailbox
        @tags = ""
      end
      # @account = @host.esp.unique_account(@account)

      @address
    end

    def hostname
      host.host
    end

    def unique_address
      "#{account}@#{hostname}"
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
