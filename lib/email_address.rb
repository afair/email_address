#require "email_address/version"
#require "email_address/config"
#require "email_address/host"
#require "email_address/address"
require 'simpleidn'

class EmailAddress
  attr_reader :address, :local, :account, :tag, :comment,
    :domain, :subdomains, :base_domain, :top_level_domain

  def initialize(email)
    self.address = email
  end

  def address=(email)
    @address = email.strip
    (local_name, domain_name) = @address.split('@')
    self.domain = domain_name
    self.local  = local_name
    @address
  end

  def to_s
    [local, domain].join('@')
  end

  ##############################################################################
  # Domain Parsing
  ##############################################################################
  def domain=(host_name)
    host_name ||= ''
    @domain = host_name.strip.downcase
    parse_domain

    @domain
  end

  def parse_domain
    @subdomains = @base_domain = @domain_name = @top_level_domain = ''
    # Patterns: *.com, *.xx.cc, *.cc
    if @domain =~ /\A(.+)\.(\w{3,10})\z/ || @domain =~ /\A(.+)\.(\w{1,3}\.\w\w)\z/ || @domain =~ /\A(.+)\.(\w\w)\z/
      @top_level_domain = $2;
      sld = $1 # Second level domain
      if @sld =~ /(.+)\.(.+)$/ # is subdomain?
        @subdomains = $1
        @base_domain = $2
      else
        @subdomains = ""
        @base_domain = sld
      end
      @domain_name  = @base_domain + '.' + @top_level_domain
    end
  end

  def dns_hostname
    @dns_hostname ||= SimpleIDN.to_ascii(domain)
  end

  ##############################################################################
  # Parsing id provider-dependent, but RFC allows:
  # A-Z a-z 0-9 . ! # $ % ' * + - / = ? ^ _ { | } ~
  # Quoted: space ( ) , : ; < > @ [ ] 
  # Quoted-Backslash-Escaped: \ " 
  # Quote local part or dot-separated sub-parts x."y".z
  # (comment)mailbox | mailbox(comment)
  # 8-bit: allowed bu mail-system defined
  # RFC 5321 also warns that "a host that expects to receive mail SHOULD avoid defining mailboxes where the Local-part requires (or uses) the Quoted-string form".
  # Postmaster: must always be case-insensitive
  # Case: sensitive, but usually treated as equivalent
  ##############################################################################
  def local=(local)
    local ||= ''
    @local = local.strip.downcase
    @account = parse_comment(@local)
    (@account, @tag) = @local.split(tag_separator)
    @tag ||= ''

    @local
  end

  def parse_comment(local)
    if @local =~ /\A\((.+?)\)(.+)\z/
      (@comment, local) = [$1, $2]
    elsif @local =~ /\A(.+)\((.+?)\)\z/
      (@comment, local) = [$1, $2]
    else
      @comment = '';
    end
    local
  end

  def provider
   # @provider ||= EmailProviders::Default.new
   'unknown'
  end

  def tag_separator
   '+'
  end

  def case_sensitive_local
   false
  end

 # Letters, numbers, period (no start) 6-30chars
 def user_pattern
   /\A[a-z0-9][\.a-z0-9]{5,29}\z/i
 end

  # Returns the unique address as simplified account@hostname
  def unique_address
    "#{account}@#{dns_hostname}"
  end

  def valid?
    return false unless @local.valid?
    return false unless @host.valid?
    true
  end

  def valid_format?
    return false unless @local.match(user_pattern)
    return false unless @host.valid_format?
    true
  end
  
end
