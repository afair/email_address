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

    # host name -
    #   * full domain name after @ for email types
    #   * fully-qualified domain name
    # host type - 
    #   :email - email address domain
    #   :mx    - email exchanger domain
    def initialize(host_name, host_type=:email)
      @host_name = host_name.downcase
      @host_type = host_type
      parse_host(@host_name)
    end

    def to_s
      @host_name
    end
      
    def parse_host(host)
      @parser = EmailAddress::DomainParser.new(host)
      @parts  = @parser.parts
      @parts.each { |k,v| instance_variable_set("@#{k}", v) }
    end

    # The host name to send to DNS lookup, Punycode-escaped
    def dns_host_name
      @dns_host_name ||= ::SimpleIDN.to_ascii(@host_name)
    end

    def normalize
      dns_host_name
    end

    # The canonical host name is the simplified, DNS host name
    def canonical
      dns_host_name
    end

    def exchanger
      return nil unless @host_type == :email
      @exchanger = EmailAddress::Exchanger.new(@host_name)
    end

    def provider
      @provider ||= @parser.provider
      if !@provider && EmailAddress::Config.options[:check_dns]
        @provider = exchanger.provider
      end
      @provider ||= :unknown
    end
    
    def matches?(*names)
      DomainMatcher.matches?(@host_name, names.flatten)
    end

    def txt(alternate_host=nil)
      Resolv::DNS.open do |dns|
        records = dns.getresources(alternate_host || self.host_name,
                         Resolv::DNS::Resource::IN::TXT)
        records.empty? ? nil : records.map(&:data).join(" ")
      end
    end

    # Parses TXT record pairs into a hash
    def txt_hash(alternate_host=nil)
      fields = {}
      record = self.txt(alternate_host)
      return fields unless record

      record.split(/\s*;\s*/).each do |pair|
        (n,v) = pair.split(/\s*=\s*/)
        fields[n.to_sym] = v
      end
      fields
    end

    def dmarc
      self.txt_hash("_dmarc." + self.host_name)
    end

  end
end
