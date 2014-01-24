require 'simpleidn'

module EmailAddress
  ##############################################################################
  # Hostname management for the email address
  # IPv6/IPv6: [128.0.0.1], [IPv6:2001:db8:1ff::a0b:dbd0]
  # Comments: (comment)example.com, example.com(comment)
  # Internationalized: Unicode to Punycode
  # Length: up to 255 characters
  # Parts for: subdomain.example.co.uk
  #     host_name:         "subdomain.example.co.uk"
  #     subdomain:         "subdomain"
  #     registration_name: "example"
  #     domain_name:       "example.co.uk"
  #     tld:               "co.uk"
  #     ip_address:        nil or "ipaddress" used in [ipaddress] syntax
  ##############################################################################
  class Host
    attr_reader :host_name, :parts, :domain_name, :registration_name,
                :tld, :subdomains, :ip_address

    def initialize(host_name)
      @host_name = host_name.downcase
      parse_host(@host_name)
    end

    def to_s
      @host_name
    end
      
    ##############################################################################
    # Domain Parsing
    # Parts: subdomains.basedomain.top-level-domain
    #
    ##############################################################################
    def parse_host(host)
      @host_name  = host.strip.downcase
      @subdomains = @registration_name = @domain_name = @tld = ''
      @ip_address = nil

      if @host_name =~ /\A\[(.+)\]\z/
        @ip_address = $1

      # Split sub.domain from .tld: *.com, *.xx.cc, *.cc
      elsif @host_name =~ /\A(.+)\.(\w{3,10})\z/ ||
            @host_name =~ /\A(.+)\.(\w{1,3}\.\w\w)\z/ ||
            @host_name =~ /\A(.+)\.(\w\w)\z/

        @tld = $2;
        sld  = $1 # Second level domain
        if sld =~ /\A(.+)\.(.+)\z/ # is subdomain? sub.example [.tld]
          @subdomains  = $1
          @registration_name = $2
        else
          @registration_name = sld
          @domain_name = sld + '.' + @tld
        end
        @domain_name = @registration_name + '.' + @tld
      end
      @parts = {host_name:@host_name, subdomain:@subdomains, domain_name:@domain_name,
       registration_name:@registration_name, tld:@tld, ip_address:@ip_address}
    end

    # The host name to send to DNS lookup, Punycode-escaped
    def dns_host_name
      @dns_host_name ||= ::SimpleIDN.to_ascii(@host_name)
    end

    # The canonical host name is the simplified, DNS host name
    def canonical
      dns_host_name
    end
  end
end
