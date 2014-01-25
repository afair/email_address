require 'simpleidn'

module EmailAddress
  ##############################################################################
  # Builds hash of host name/domain name parts 
  # For: subdomain.example.co.uk
  #     host_name:         "subdomain.example.co.uk"
  #     subdomains:        "subdomain"
  #     registration_name: "example"
  #     domain_name:       "example.co.uk"
  #     tld:               "co.uk"
  #     ip_address:        nil or "ipaddress" used in [ipaddress] syntax
  ##############################################################################
  class DomainParser
    attr_reader :host_name, :parts, :domain_name, :registration_name,
                :tld, :subdomains, :ip_address

    def self.parse(domain)
      EmailAddress::DomainParser.new(domain).parts
    end

    def initialize(host_name)
      @host_name = host_name.downcase
      parse_host(@host_name)
    end

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
      @parts = {host_name:@host_name, subdomains:@subdomains, domain_name:@domain_name,
       registration_name:@registration_name, tld:@tld, ip_address:@ip_address}
    end

  end
end
