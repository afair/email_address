require 'resolv'
require 'netaddr'
require 'socket'

module EmailAddress
  class Exchanger
    def initialize(host, options={})
      @host = host
      @options = options
    end

    # True if the DNS A record or MX records are defined
    # Why A record? Some domains are misconfigured with only the A record. 
    def valid?
      has_dns_a_record? || valid_mx?
    end

    # True if the DNS MX records have been defined. More strict than #valid?
    def valid_mx?
      mxers.size > 0
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
    end

    # Returns Array of domain names for the MX'ers, used to determine the Provider
    def domains
      mxers.map {|m| EmailAddress::DomainParser.new(m.first).domain_name}.sort.uniq
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
