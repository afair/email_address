require 'resolv'
require 'netaddr'
require 'socket'

module EmailAddress
  class Exchanger
    def initialize(host, options={})
      @host = host
      @options = options
    end

    def valid?
    end

    def self.valid_mx?
      dns_a_record_exists?(domain) || mxers(domain).size > 0
    end

    def dns_a_record
      @_dns_a_record ||= Socket.gethostbyname(@host)
    rescue SocketError # not found
      @_dns_a_record ||= []
    end

    def has_dns_a_record?
      dns_a_record.size > 0 ? true : false
    end

    # Returns: [["mta7.am0.yahoodns.net", "66.94.237.139", 1], ["mta5.am0.yahoodns.net", "67.195.168.230", 1], ["mta6.am0.yahoodns.net", "98.139.54.60", 1]]
    # If not found, returns []
    def mxers
      Resolv::DNS.open do |dns|
        ress = dns.getresources(@host, Resolv::DNS::Resource::IN::MX)
        ress.map { |r| [r.exchange.to_s, IPSocket::getaddress(r.exchange.to_s), r.preference] }
      end
    end

    # Returns an array of MX IP address (String) for the given email domain
    def mx_ips
      mxers(domain).map {|m| m[1] }
    end

    # Given a cidr (ip/bits) and ip address, returns true on match. Caches cidr object.
    def self.in_cidr?(cidr)
      @cidr ||= NetAddr::CIDR.create(cidr)
      if 0 < mx_ips.reduce(0) { |ip| @cider.matches?(ip) }
        true
      else
        false
      end
    end
  end
end
