require 'resolv'
require 'netaddr'
require 'socket'

class MailExchanger
  cattr_accessor :domains, :lookups
  
  def self.valid_mx?(domain)
    dns_a_record_exists?(domain) || mxers(domain).size > 0
  end

  def self.dns_a_record_exists?(domain)
    @dns_a_record ||= {}
    @dns_a_record[domain] = false
    if Socket.gethostbyname(domain)
      return @dns_a_record[domain] = true
    end
  rescue SocketError # not found
      @dns_a_record[domain] = false
  end

  # Returns DNS A record results for the domain as: [[domain, ip, 0],...]
  def self.domain_hosts(domain)
    @domain_hosts ||= {}
    @domain_hosts[domain] = []
    res = TCPSocket.gethostbyname(domain)
    res = res.slice(3, res.size)
    res.each { |r| @domain_hosts[domain] << [domain, r, 0] }
    @domain_hosts[domain]

    rescue SocketError
      return []
  end

  # Returns: [["mta7.am0.yahoodns.net", "66.94.237.139", 1], ["mta5.am0.yahoodns.net", "67.195.168.230", 1], ["mta6.am0.yahoodns.net", "98.139.54.60", 1]]
  # If not found, returns []
  def self.mxers(domain)
    @domains ||= {}
    return @domains[domain] if @domains.key?(domain)
    @lookups = @lookups ? @lookups + 1 : 1
    mx = nil
    mxs = Resolv::DNS.open do |dns|
      ress = dns.getresources domain, Resolv::DNS::Resource::IN::MX
      ress.map { |r| [r.exchange.to_s, IPSocket::getaddress(r.exchange.to_s), r.preference] }
    end
    @domains[domain] = mxs
  end

  # Returns an array of MX IP address (String) for the given email domain
  def self.mx_ips(domain)
    mxers(domain).map {|m| m[1] }
  end

  # Given a cidr (ip/bits) and ip address, returns true on match. Caches cidr object.
  def self.in_cidr?(cidr, ip)
    @cidrs ||= {}
    @cidrs[cidr] ||= NetAddr::CIDR.create(cidr)
    @cidrs[cidr].matches?(ip)
  end
end
