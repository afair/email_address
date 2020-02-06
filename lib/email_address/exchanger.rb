# frozen_string_literal: true

require 'resolv'
require 'netaddr'
require 'socket'

module EmailAddress
  class Exchanger
    include Enumerable

    def self.cached(host, config={})
      @host_cache ||= {}
      @cache_size ||= ENV['EMAIL_ADDRESS_CACHE_SIZE'].to_i || 100
      if @host_cache.has_key?(host)
        exchanger = @host_cache.delete(host)
        exchanger = new(host, config) if exchanger.network_was_down?
        @host_cache[host] = exchanger # LRU cache, move to end
      else
        if @host_cache.size >= @cache_size
          @host_cache.delete(@host_cache.keys.first)
        end
        exchanger = @host_cache[host] = new(host, config)
      end
      exchanger
    end

    def initialize(host, config={})
      @host = host
      @config = config
      @network_down_at = nil
    end

    def each(&block)
      mxers.each do |m|
        yield({host:m[0], ip:m[1], priority:m[2]})
      end
    end

    # Returns the provider name based on the MX-er host names, or nil if not matched
    def provider
      return @provider if defined? @provider
      EmailAddress::Config.providers.each do |provider, config|
        if config[:exchanger_match] && self.matches?(config[:exchanger_match])
          return @provider = provider
        end
      end
      @provider = :default
    end

    # Returns: [official_hostname, alias_hostnames, address_family, *address_list]
    def a_record
      @_a_record = [@host, [], 2, ""] if @config[:dns_lookup] == :off
      @_a_record ||= Socket.gethostbyname(@host)
    rescue SocketError # not found, but could also mean network not work
      if network_down?
        @_a_record = [@host, [], 2, ""]
      else
        @_a_record ||= []
      end
    end

    def network_down?
      return false if @config[:dns_lookup] == :off
      return false if @config[:dns_unavailable] == :ignore

      Socket.gethostbyname('example.com') # Should always exist
      @network_down_at = nil
      false
    rescue SocketError # DNS Failed, so network is down
      @network_down_at = Time.new
      true
    end

    def network_was_down?
      @network_down_at ? true : false
    end

    # Returns: [["mta7.am0.yahoodns.net", "66.94.237.139", 1], ["mta5.am0.yahoodns.net", "67.195.168.230", 1], ["mta6.am0.yahoodns.net", "98.139.54.60", 1]]
    # If not found, returns []
    # Returns a dummy record when dns_lookup is turned off since it may exists, though
    # may not find provider by MX name or IP. I'm not sure about the "0.0.0.0" ip, it should
    # be good in this context, but in "listen" context it means "all bound IP's"
    def mxers
      return [[@host, "0.0.0.0", 1]] if @config[:dns_lookup] == :off
      @mxers ||= Resolv::DNS.open do |dns|
        dns.timeouts = @config[:dns_timeout] if @config[:dns_timeout]

        ress = begin
          dns.getresources(@host, Resolv::DNS::Resource::IN::MX)
        rescue Resolv::ResolvTimeout
          []
        end
        return [[@host, "0.0.0.0", 1]] if ress.empty? && network_down?

        records = ress.map do |r|
          begin
            if r.exchange.to_s > " "
              [r.exchange.to_s, IPSocket::getaddress(r.exchange.to_s), r.preference]
            else
              nil
            end
          rescue SocketError
            if network_down?
              [@host, "0.0.0.0", 1]
            else # Not Found
              nil
            end
          end
        end
        records.compact
      end
    end

    # Returns Array of domain names for the MX'ers, used to determine the Provider
    def domains
      @_domains ||= mxers.map {|m| EmailAddress::Host.new(m.first).domain_name }.sort.uniq
    end

    # Returns an array of MX IP address (String) for the given email domain
    def mx_ips
      return ["0.0.0.0"] if @config[:dns_lookup] == :off
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
      if cidr.include?(":")
        c = NetAddr::IPv6Net.parse(cidr)
        return true if mx_ips.find do |ip|
          next unless ip.include?(":")
          rel = c.rel NetAddr::IPv6Net.parse(ip)
          !rel.nil? && rel >= 0
        end
      elsif cidr.include?(".")
        c = NetAddr::IPv4Net.parse(cidr)
        return true if mx_ips.find do |ip|
          next if ip.include?(":")
          rel = c.rel NetAddr::IPv4Net.parse(ip)
          !rel.nil? && rel >= 0
        end
      end
      false
    end
  end
end
