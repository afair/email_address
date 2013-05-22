#require "email_address/version"
#require "email_address/config"
#require "email_address/host"
#require "email_address/address"
require 'simpleidn'

class EmailAddress
  attr_reader :address, :local, :account, :tag, :comment,
    :domain, :subdomains, :domain_name, :base_domain, :top_level_domain

  def initialize(email)
    self.address = email
  end

  ##############################################################################
  # Basic email address: local@domain
  # Only supporting FQDN's (Fully Qualified Domain Names)?
  # Length: Up to 254 characters
  ##############################################################################
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
  # Parts: subdomains.basedomain.top-level-domain
  # IPv6/IPv6: [128.0.0.1], [IPv6:2001:db8:1ff::a0b:dbd0]
  # Comments: (comment)example.com, example.com(comment)
  # Internationalized: Unicode to Punycode
  # Length: up to 255 characters
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
      if sld =~ /\A(.+)\.(.+)\z/ # is subdomain? sub.example [.tld]
        @subdomains  = $1
        @base_domain = $2
      else
        @subdomains  = ""
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
  # 8-bit/UTF-8: allowed but mail-system defined
  # RFC 5321 also warns that "a host that expects to receive mail SHOULD avoid defining mailboxes where the Local-part requires (or uses) the Quoted-string form".
  # Postmaster: must always be case-insensitive
  # Case: sensitive, but usually treated as equivalent
  # Local Parts: comment, account tag
  # Length: upt o 64 cgaracters
  ##############################################################################
  def local=(local)
    local ||= ''
    @local = local.strip.downcase
    @account = parse_comment(@local)
    (@account, @tag) = @account.split(tag_separator)
    @tag ||= ''

    @local
  end

  def parse_comment(local)
    if local =~ /\A\((.+?)\)(.+)\z/
      (@comment, local) = [$1, $2]
    elsif @local =~ /\A(.+)\((.+?)\)\z/
      (@comment, local) = [$1, $2]
    else
      @comment = '';
    end
    local
  end

  ##############################################################################
  # Provider-Specific Settings
  ##############################################################################

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

  # Returns the unique address as simplified account@hostname
  def unique_address
    "#{account}@#{dns_hostname}".downcase
  end

  # Letters, numbers, period (no start) 6-30chars
  def user_pattern
   /\A[a-z0-9][\.a-z0-9]{0,29}\z/i
  end

  ##############################################################################
  # Validations -- Eventually a provider-sepecific check
  ##############################################################################
  def valid?
    return false unless @local =~ user_pattern
    return false unless provider # .valid_domain
    true
  end

  def valid_format?
    return false unless @local.match(user_pattern)
    return false unless @host.valid_format?
    true
  end

end
