# EmailAddress::Address
# EmailAddress::Host
# EmailAddress::MailExchanger
# EmailAddress::Config
# EmailAddress::EspMapping
# EmailAddress::Esp::Base, Yahoo, Msn, ...

require 'simpleidn'

module EmailAddress

  # EmailAddress::Host handles mail host properties of an email address
  # The host is typically the data to the right of the @ in the address
  # and consists of:
  #
  # * hostname - full name of DNS host with the MX record.
  # * domain_name - generally, the name and TLD without subdomain
  # * base_domain - the identity name of the domain name, without the tld
  # * tld (top-level-domain), like .com, .co.jp, .com.xx, etc.
  # * subdomain - optional name of server/service under the domain
  # * esp (email service provider) a name of the provider: yahoo, msn, etc.
  # * dns_hostname - Converted hostname Unicode to Punycode

  class Host
    attr_reader :host, :domain_name, :tld, :base_domain, :subdomains, :dns_hostname

    def initialize(host)
      host.gsub!(/\A.*@/, '')
      host.downcase!
      self.host = host
    end

    def address(mailbox)
      # Determine EmailAddress::Provider::Xxxx
      EmailAddress::Address.new(mailbox, self)
    end

    def host=(host)
      @host = host
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
        @domain_name  = @base_domain + '.' + @tld
        @dns_hostname = SimpleIDN.to_ascii(@host)
        @host
      end
    end

    # Resets the host to the domain name, dropping any subdomain
    def drop_subdomain!
      self.hostname = domain_name
    end

    def valid?
      return false unless valid_format?
      return false unless valid_mx?
      true
    end

    def valid_format?
      Host.valid_format?(@host)
    end

    def self.valid_format?(host)
      return false unless host.match(/\A([0-9a-z\-]{1,63}\.)+[a-z0-9\-]{2,15}\z/)
      return false unless host.length <= 253
      true
    end

    def valid_mx?
      Host.valid_mx?(@host)
    end

    def self.valid_mx?(host)
      true
    end

  end
end
