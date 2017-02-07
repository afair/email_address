require 'resolv'
require 'netaddr'
require 'socket'

module EmailAddress
  class Exchanger
    include Enumerable

    def self.cached(host)
      @host_cache ||= {}
      @cache_size ||= ENV['EMAIL_ADDRESS_CACHE_SIZE'].to_i || 100
      if @host_cache.has_key?(host)
        o = @host_cache.delete(host)
        @host_cache[host] = o # LRU cache, move to end
      elsif @host_cache.size >= @cache_size
        @host_cache.delete(@host_cache.keys.first)
        @host_cache[host] = new(host)
      else
        @host_cache[host] = new(host)
      end
    end

    def initialize(host, config={})
      @host = host
      @config = config
    end

    def each(&block)
      mxers.each do |m|
        yield({host:m[0], ip:m[1], priority:m[2]})
      end
    end

    # Returns the provider name based on the MX-er host names, or nil if not matched
    def provider
      return @provider if @provider
      EmailAddress::Config.providers.each do |provider, config|
        if config[:exchanger_match] && self.matches?(config[:exchanger_match])
          return @provider = provider
        end
      end
      @provider = :default
    end

    # Returns: [["mta7.am0.yahoodns.net", "66.94.237.139", 1], ["mta5.am0.yahoodns.net", "67.195.168.230", 1], ["mta6.am0.yahoodns.net", "98.139.54.60", 1]]
    # If not found, returns []
    def mxers
      @mxers ||= Resolv::DNS.open do |dns|
        ress = dns.getresources(@host, Resolv::DNS::Resource::IN::MX)
        ress.map do |r|
          begin
            [r.exchange.to_s, IPSocket::getaddress(r.exchange.to_s), r.preference]
          rescue SocketError # not found, but could also mean network not work or it could mean one record doesn't resolve an address
            []
          end
        end
      end
    end

    # Returns Array of domain names for the MX'ers, used to determine the Provider
    def domains
      @_domains ||= mxers.map {|m| EmailAddress::Host.new(m.first).domain_name }.sort.uniq
    end

    # Returns an array of MX IP address (String) for the given email domain
    def mx_ips
      mxers.map {|m| m[1] }
    end

    # Simple matcher, takes an array of CIDR addresses (ip/bits) and strings.
    # Returns true if any MX IP matches the CIDR or host name ends in string.
    # Ex: match?(%w(127.0.0.1/32 0:0:1/64 .yahoodns.net))
    # Note: Your networking stack may return IPv6 addresses instead of IPv4
    # when both are available. If matching on IP, be sure to include both
    # IPv4 and IPv6 forms for matching for hosts running on IPv6 (like gmail).
    def matches?(rules)
      rules = Array(rules)
      rules.each do |rule|
        if rule.include?("/")
          return rule if self.in_cidr?(rule)
        else
          self.each {|mx| return rule if mx[:host].end_with?(rule) }
        end
      end
      false
    end

    # Given a cidr (ip/bits) and ip address, returns true on match. Caches cidr object.
    def in_cidr?(cidr)
      c = NetAddr::CIDR.create(cidr)
      if cidr.include?(":")
        mx_ips.find { |ip| ip.include?(":") && c.matches?(ip) } ? true : false
      elsif cidr.include?(".")
        mx_ips.find { |ip| !ip.include?(":") && c.matches?(ip) } ? true : false
      else
        false
      end
    end
  end
end
