module EmailAddress
  # host_name - Full hostname
  # domain_name - (Probably) the registered domain name
  # sub_domain_name - Anything to the "left" of domain name
  # tld - Last one (or two) Top Level Domain Qualifiers
  # esp - "Email Service Provider" name of the domain name
  class Host
    attr_reader :tld, :subdomains, :domain_name, :registration_name, :hostl_name

    def initialize(host_name)
      @host_name = host_name.downcase
      parse_domain
    end

    def to_s
      @host_name
    end
      
    ##############################################################################
    # Domain Parsing
    # Parts: subdomains.basedomain.top-level-domain
    # IPv6/IPv6: [128.0.0.1], [IPv6:2001:db8:1ff::a0b:dbd0]
    # Comments: (comment)example.com, example.com(comment)
    # Internationalized: Unicode to Punycode
    # Length: up to 255 characters
    ##############################################################################
    def parse_host(host)
      host = host.strip.downcase
      @subdomains = @domain_name = @tld = ''
      # Patterns: *.com, *.xx.cc, *.cc
      if @host_name =~ /\A(.+)\.(\w{3,10})\z/ ||
         @host_name =~ /\A(.+)\.(\w{1,3}\.\w\w)\z/ ||
         @host_name =~ /\A(.+)\.(\w\w)\z/
        @tld = $2;
        sld = $1 # Second level domain
        if sld =~ /\A(.+)\.(.+)\z/ # is subdomain? sub.example [.tld]
          @subdomains  = $1
          @domain_part = $2
        else
          @subdomains  = ""
          @domain_name = sld
        end
        @domain_name  = @domain_part + '.' + @tld
      end
    end

    # The host name to send to DNS lookup, Punycode-escaped
    def dns_host_name
      @dns_host_name ||= SimpleIDN.to_ascii(@host_name)
    end

    # The canonical host name is the simplified, DNS host name
    def canonical
      dns_host_name
    end
  end
end
