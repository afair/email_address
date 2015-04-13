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

    def initialize(host, options={})
      @host = host
      @options = options
    end

    def each(&block)
      mxers.each do |m|
        yield({host:m[0], ip:m[1], priority:m[2]})
      end
    end

    # Returns the provider name based on the MX-er host names, or nil if not matched
    def provider
      base = EmailAddress::Config.providers[:default]
      EmailAddress::Config.providers.each do |name, defn|
        defn = base.merge(defn)
        self.each do |m|
         return name if DomainMatcher.matches?(m[:host], defn[:exchangers])
        end
      end
      nil
    end

    def has_dns_a_record?
      dns_a_record.size > 0 ? true : false
    end

    def dns_a_record
      @_dns_a_record ||= Socket.gethostbyname(@host)
    rescue SocketError # not found, but could also mean network not work
      @_dns_a_record ||= []
    end

    # Returns: [["mta7.am0.yahoodns.net", "66.94.237.139", 1], ["mta5.am0.yahoodns.net", "67.195.168.230", 1], ["mta6.am0.yahoodns.net", "98.139.54.60", 1]]
    # If not found, returns []
    def mxers
      @mxers ||= Resolv::DNS.open do |dns|
        ress = dns.getresources(@host, Resolv::DNS::Resource::IN::MX)
        ress.map { |r| [r.exchange.to_s, IPSocket::getaddress(r.exchange.to_s), r.preference] }
      end
    rescue SocketError # not found, but could also mean network not work
      @_dns_a_record ||= []
    end

    # Returns Array of domain names for the MX'ers, used to determine the Provider
    def domains
      mxers.map {|m| EmailAddress::DomainParser.new(m.first).domain_name}.sort.uniq
    end

    # Returns an array of MX IP address (String) for the given email domain
    def mx_ips
      mxers.map {|m| m[1] }
    end

    # Given a cidr (ip/bits) and ip address, returns true on match. Caches cidr object.
    def in_cidr?(cidr)
      @cidr ||= NetAddr::CIDR.create(cidr)
      mx_ips.first { |ip| @cider.matches?(ip) } ? true : false
    end
  end
end
