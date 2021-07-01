# frozen_string_literal: true

require "resolv"
require "socket"

module EmailAddress
  class Exchanger
    include Enumerable

    def self.cached(host, config = {})
      @host_cache ||= {}
      @cache_size ||= ENV["EMAIL_ADDRESS_CACHE_SIZE"].to_i || 100
      if @host_cache.has_key?(host)
        o = @host_cache.delete(host)
        @host_cache[host] = o # LRU cache, move to end
      elsif @host_cache.size >= @cache_size
        @host_cache.delete(@host_cache.keys.first)
        @host_cache[host] = new(host, config)
      else
        @host_cache[host] = new(host, config)
      end
    end

    def initialize(host, config = {})
      @host = host
      @config = config.is_a?(Hash) ? Config.new(config) : config
      @dns_disabled = @config[:host_validation] == :syntax || @config[:dns_lookup] == :off
    end

    def each(&block)
      return if @dns_disabled
      mxers.each do |m|
        yield({host: m[0], ip: m[1], priority: m[2]})
      end
    end

    # Returns the provider name based on the MX-er host names, or nil if not matched
    def provider
      return @provider if defined? @provider
      Config.providers.each do |provider, config|
        if config[:exchanger_match] && matches?(config[:exchanger_match])
          return @provider = provider
        end
      end
      @provider = :default
    end

    # Returns: [["mta7.am0.yahoodns.net", "66.94.237.139", 1], ["mta5.am0.yahoodns.net", "67.195.168.230", 1], ["mta6.am0.yahoodns.net", "98.139.54.60", 1]]
    # If not found, returns []
    # Returns a dummy record when dns_lookup is turned off since it may exists, though
    # may not find provider by MX name or IP. I'm not sure about the "0.0.0.0" ip, it should
    # be good in this context, but in "listen" context it means "all bound IP's"
    def mxers
      return [["example.com", "0.0.0.0", 1]] if @dns_disabled
      @mxers ||= Resolv::DNS.open { |dns|
        dns.timeouts = @config[:dns_timeout] if @config[:dns_timeout]

        ress = begin
          dns.getresources(@host, Resolv::DNS::Resource::IN::MX)
        rescue Resolv::ResolvTimeout
          []
        end

        records = ress.map { |r|
          if r.exchange.to_s > " "
            [r.exchange.to_s, IPSocket.getaddress(r.exchange.to_s), r.preference]
          end
        }
        records.compact
      }
    # not found, but could also mean network not work or it could mean one record doesn't resolve an address
    rescue SocketError
      [["example.com", "0.0.0.0", 1]]
    end

    # Returns Array of domain names for the MX'ers, used to determine the Provider
    def domains
      @_domains ||= mxers.map { |m| Host.new(m.first).domain_name }.sort.uniq
    end

    # Returns an array of MX IP address (String) for the given email domain
    def mx_ips
      return ["0.0.0.0"] if @dns_disabled
      mxers.map { |m| m[1] }
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
          return rule if in_cidr?(rule)
        else
          each { |mx| return rule if mx[:host].end_with?(rule) }
        end
      end
      false
    end

    # Given a cidr (ip/bits) and ip address, returns true on match. Caches cidr object.
    def in_cidr?(cidr)
      net = IPAddr.new(cidr)
      found = mx_ips.detect { |ip| net.include?(IPAddr.new(ip)) }
      !!found
    end
  end
end
