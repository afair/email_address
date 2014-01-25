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
      
    def parse_host(host)
      @parts = EmailAddress::DomainParser.parse(host)
      @parts.each { |k,v| instance_variable_set("@#{k}", v) }
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
