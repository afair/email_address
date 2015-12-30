require 'simpleidn'
require 'resolv'
require 'netaddr'

module EmailAddress
  ##############################################################################
  # Hostname management for the email address
  # IPv6/IPv6: [128.0.0.1], [IPv6:2001:db8:1ff::a0b:dbd0]
  # Comments: (comment)example.com, example.com(comment)
  # Internationalized: Unicode to Punycode
  # Length: up to 255 characters
  # Parts for: subdomain.example.co.uk
  #     host_name:         "subdomain.example.co.uk"
  #     dns_name:          punycode("subdomain.example.co.uk")
  #     subdomain:         "subdomain"
  #     registration_name: "example"
  #     domain_name:       "example.co.uk"
  #     tld:               "uk"
  #     tld2:              "co.uk"
  #     ip_address:        nil or "ipaddress" used in [ipaddress] syntax
  ##############################################################################
  class Host
    attr_accessor :host_name, :dns_name, :domain_name, :registration_name,
                  :tld, :tld2, :subdomains, :ip_address, :config, :provider

    # host name -
    #   * full domain name after @ for email types
    #   * fully-qualified domain name
    # host type -
    #   :email - email address domain
    #   :mx    - email exchanger domain
    def initialize(host_name, config={})
      @original  = host_name ||= ''
      @host_type = config[:host_type] || :email
      @config    = config
      parse(host_name)
    end

    def name
      if self.ipv4?
        "[#{self.ip_address}]"
      elsif self.ipv6?
        "[IPv6:#{self.ip_address}]"
      elsif @config[:host_encoding] && @config[:host_encoding] == :unicode
        ::SimpleIDN.to_unicode(self.host_name)
      else
        self.dns_name
      end
    end
    alias :to_s :name

    # The canonical host name is the simplified, DNS host name
    def canonical
      self.dns_name
    end

    ############################################################################
    # Parsing
    ############################################################################

    def parse(host)
      if host =~ /\A\[IPv6:(.+)\]/i
        self.ip_address = $1
      elsif host =~ /\A\[(\d{1,3}(\.\d{1,3}){3})\]/ # IPv4
        self.ip_address = $1
      else
        self.host_name = host
      end
    end

    def host_name=(name)
      @host_name = name = name.strip.downcase.gsub(' ', '').gsub(/\(.*\)/, '')
      @dns_name  = ::SimpleIDN.to_ascii(self.host_name)

      # Subdomain only (root@localhost)
      if name.index('.').nil?
        self.subdomains = name

      # Split sub.domain from .tld: *.com, *.xx.cc, *.cc
      elsif name =~ /\A(.+)\.(\w{3,10})\z/ ||
            name =~ /\A(.+)\.(\w{1,3}\.\w\w)\z/ ||
            name =~ /\A(.+)\.(\w\w)\z/

        sld  = $1 # Second level domain
        self.tld2 = self.tld = $2;
        self.tld = self.tld.sub(/\A.+\./, '') # co.uk => uk
        if sld =~ /\A(.+)\.(.+)\z/ # is subdomain? sub.example [.tld2]
          self.subdomains  = $1
          self.registration_name = $2
        else
          self.registration_name = sld
          self.domain_name = sld + '.' + self.tld2
        end
        self.domain_name = self.registration_name + '.' + self.tld2
        self.find_provider
      end
    end

    def find_provider
      return self.provider if self.provider

      EmailAddress::Config.providers.each do |provider, config|
        if config[:host_match] && self.matches?(config[:host_match])
          return self.set_provider(provider, config)
        end
      end

      return self.set_provider(:default) unless self.dns_enabled?

      provider = self.exchangers.provider
      if provider != :default
        self.set_provider(provider,
          EmailAddress::Config.provider(self.provider))
      end

      self.provider ||= self.set_provider(:default)
    end

    def set_provider(name, provider_config={})
      self.config = EmailAddress::Config.all_settings(provider_config, @config)
      self.provider = name
    end

    ############################################################################
    # Access and Queries
    ############################################################################

    # Is this a fully-qualified domain name?
    def fqdn?
      self.tld ? true : false
    end

    def ip?
      self.ip_address.nil? ? false : true
    end

    def ipv4?
      self.ip? && self.ip_address.include?(".")
    end

    def ipv6?
      self.ip? && self.ip_address.include?(":")
    end

    ############################################################################
    # Matching
    ############################################################################

    # Takes a email address string, returns true if it matches a rule
    # Rules of the follow formats are evaluated:
    # * "example."  => registration name
    # * ".com"      => top-level domain name
    # * "google"    => email service provider designation
    # * "@goog*.com" => Glob match
    # * IPv4 or IPv6 or CIDR Address
    def matches?(rules)
      rules = Array(rules)
      return false if rules.empty?
      rules.each do |rule|
        return rule if rule == self.domain_name || rule == self.dns_name
        return rule if registration_name_matches?(rule)
        return rule if tld_matches?(rule)
        return rule if domain_matches?(rule)
        return rule if self.provider && provider_matches?(rule)
        return rule if self.ip_matches?(rule)
      end
      false
    end

    # Does "example." match any tld?
    def registration_name_matches?(rule)
      self.registration_name + '.' == rule ? true : false
    end

    # Does "sub.example.com" match ".com" and ".example.com" top level names?
    # Matches TLD (uk) or TLD2 (co.uk)
    def tld_matches?(rule)
      rule.match(/\A\.(.+)\z/) && ($1 == self.tld || $1 == self.tld2) ? true : false
    end

    def provider_matches?(rule)
      rule.to_s =~ /\A[\w\-]*\z/ && self.provider && self.provider == rule.to_sym
    end

    # Does domain == rule or glob matches? (also tests the DNS (punycode) name)
    # Requires optionally starts with a "@".
    def domain_matches?(rule)
      rule = $1 if rule =~ /\A@(.+)/
      return rule if File.fnmatch?(rule, self.domain_name)
      return rule if File.fnmatch?(rule, self.dns_name)
      false
    end

    def ip_matches?(cidr)
      return false unless self.ip_address
      return cidr if !cidr.include?("/") && cidr == self.ip_address

      c = NetAddr::CIDR.create(cidr)
      if cidr.include?(":") && self.ip_address.include?(":")
        return cidr if c.matches?(self.ip_address)
      elsif cidr.include?(".") && self.ip_address.include?(".")
        return cidr if c.matches?(self.ip_address)
      end
      false
    end

    ############################################################################
    # DNS
    ############################################################################

    def dns_enabled?
      EmailAddress::Config.setting(:dns_lookup)
    end

    def has_dns_a_record?
      dns_a_record.size > 0 ? true : false
    end

    # Returns: [official_hostname, alias_hostnames, address_family, *address_list]
    def dns_a_record
      @_dns_a_record ||= Socket.gethostbyname(@host)
    rescue SocketError # not found, but could also mean network not work
      @_dns_a_record ||= []
    end

    def exchangers
      return nil if @host_type != :email || !self.dns_enabled?
      @_exchangers ||= EmailAddress::Exchanger.cached(self.dns_name)
    end

    # Returns a DNS TXT Record
    def txt(alternate_host=nil)
      Resolv::DNS.open do |dns|
        records = dns.getresources(alternate_host || self.dns_name,
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
      self.txt_hash("_dmarc." + self.dns_name)
    end

    ############################################################################
    # Validation
    ############################################################################

    def valid?(rule=@config[:host_validation]||:mx)
      if self.provider != :default # well known
        true
      elsif self.ip_address
        @config[:host_allow_ip] && self.valid_ip?
      elsif rule == :mx
        true
      elsif rule == :a
        true
      else
        false
      end
    end

    def valid_ip?
      if self.ip_address.include?(":")
        self.ip_address =~ Resolv::IPv6::Regex
      elsif self.ip_address.include?(".")
        self.ip_address =~ Resolv::IPv4::Regex
      end
    end

  end
end
