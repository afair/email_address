module EmailAddress

  # EmailAddress::Mailbox - Left side of the @
  #
  # * mailbox - Everything to the left of the @
  # * account - part of the mailbox typically sent to a user
  # * tags - Address tags appended to the account for tracking
  #
  class Mailbox
    attr_reader :mailbox, :account, :tags, :provider

    def initialize(mailbox, mail_provider=nil)
      @provider = mail_provider
      @mailbox  = mailbox
    end

    def to_s
      @mailbox
    end

    def mailbox=(mailbox)
      @mailbox = mailbox.strip.downcase
      (@account, @tags) = @mailbox.split(@provider.tag_separator)
      @mailbox
    end

    def valid?
      return false unless provider.valid?(mailbox)
      true
    end

    def valid_format?
      return false unless provider.valid_format?(mailbox)
      #return false unless @mailbox =~ /\A\w[\w\.\-\+\']*\z/
      true
    end

    # Returns true if the email account is a standard reserved address
    def reserved?
      %Q(postmaster abuse).include?(account)
    end
    
  end
end
