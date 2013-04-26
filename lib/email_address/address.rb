module EmailAddress

  # EmailAddress::Address - Inspects a Email Address.
  #
  # * hostname - Everything to the rigth of the @
  # * mailbox - Everything to the left of the @
  #
  class Address
    attr_reader :address, :mailbox, :host, :account, :tags

    def initialize(mailbox, host_object)
      self.mailbox = mailbox
      @host        = host_object
    end

    def mailbox=(mailbox)
      @mailbox = mailbox.strip.downcase
      (@account, @tags) = @mailbox.split(tag_separator)
      @mailbox
    end

    def address=(address)
      @address = address.strip
      (mailbox_name, host_name) = @address.split(/\@/)
      return unless host_part

      @mailbox_name = mailbox_name
      @host         = EmailAddress::Host.new(host_part)
      @mailbox      = host.provider_mailbox(mailbox_part, @host)
      @address
    end

    def provider
     'unknown'
    end

    def tag_separator
     '+'
    end

    def case_sensitive_mailbox
     false
    end

   # Letters, numbers, period (no start) 6-30chars
   def user_pattern
     /\A[a-z0-9][\.a-z0-9]{5,29}\z/i
   end

    # Returns the unique address as simplified account@hostname
    def unique_address
      "#{account}@#{dns_hostname}"
    end

    def valid?
      return false unless @mailbox.valid?
      return false unless @host.valid?
      true
    end

    def valid_format?
      return false unless @mailbox.match(user_pattern)
      return false unless @host.valid_format?
      true
    end
    
    ############################################################################
    # Host Deletation: domain parts
    ############################################################################

    # Returns the fully-qualified host name (everything to the right of the @).
    def hostname
      host.host
    end

    # Returns the host without any subdomains (domain.tld(
    def domain_name
      host.domain_name
    end

    # Returns the Top-Level-Domain parts (after domain): com, co.jp
    def tld
      host.tld
    end

    # Returns the registration name without subdomains or TLD.
    def base_domain 
      host.base_domain
    end

    # Returns any given subdomains of the domain name
    def subdomains
      host.subdomains
    end

    # Returns an ASCII name for DNS lookup, Punycode for Unicode domains.
    def dns_hostname
      host.dns_hostname
    end

  end
end
