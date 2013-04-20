require "email_address/version"

module EmailAddress
  # Your code goes here...
  class Address
    attr_reader :mailbox, :host, :domain, :tld, :base_domain, :subdomains

    def initialize(address)
      @address = address
      parse_address
    end

    def parse_address
      (@user, @host) = @address.split(/\@/)
      return unless @host
      @host.downcase!

      # Patterns: *.com, *.xx.cc, *.cc
      if @host =~ /(.+)\.(\w{3,10})\z/ || @host =~ /(.+)\.(\w{1,3}\.\w\w)\z/ || @host =~ /(.+)\.(\w\w)\z/
        @tld = $2;
        sld = $1 # Second level domain
        if @sld =~ /(.+)\.(.+)$/ # is subdomain?
          @subdomains = $1
          @base_domain = $2
        else
          @subdomains = ""
          @base_domain = sld
        end
        @domain = @base_domain + '.' + @tld
      end
    end
    
  end
end
