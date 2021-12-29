# frozen_string_literal: true

require "digest/sha1"
require "digest/sha2"
require "digest/md5"

module EmailAddress
  # Implements the Email Address container, which hold the Local
  # (EmailAddress::Local) and Host (EmailAddress::Host) parts.
  class Address
    include Comparable
    include Rewriter

    attr_accessor :original, :local, :host, :config, :reason, :locale

    CONVENTIONAL_REGEX = /\A#{Local::CONVENTIONAL_MAILBOX_WITHIN}
                           @#{Host::DNS_HOST_REGEX}\z/x
    STANDARD_REGEX = /\A#{Local::STANDARD_LOCAL_WITHIN}
                           @#{Host::DNS_HOST_REGEX}\z/x
    RELAXED_REGEX = /\A#{Local::RELAXED_MAILBOX_WITHIN}
                           @#{Host::DNS_HOST_REGEX}\z/x

    # Given an email address of the form "local@hostname", this sets up the
    # instance, and initializes the address to the "normalized" format of the
    # address. The original string is available in the #original method.
    def initialize(email_address, config = {}, locale = "en")
      @config = Config.new(config)
      @original = email_address
      @locale = locale
      email_address = (email_address || "").strip
      email_address = parse_rewritten(email_address) unless config[:skip_rewrite]
      local, host = Address.split_local_host(email_address)

      @host = Host.new(host, @config, locale)
      @local = Local.new(local, @config, @host, locale)
      @error = @error_message = nil
    end

    # Given an email address, this returns an array of [local, host] parts
    def self.split_local_host(email)
      if (lh = email.match(/(.+)@(.+)/))
        lh.to_a[1, 2]
      else
        [email, ""]
      end
    end

    ############################################################################
    # Local Part (left of @) access
    # * local: Access full local part instance
    # * left: everything on the left of @
    # * mailbox: parsed mailbox or email account name
    # * tag: address tag (mailbox+tag)
    ############################################################################

    # Everything to the left of the @ in the address, called the local part.
    def left
      local.to_s
    end

    # Returns the mailbox portion of the local port, with no tags. Usually, this
    # can be considered the user account or role account names. Some systems
    # employ dynamic email addresses which don't have the same meaning.
    def mailbox
      local.mailbox
    end

    # Returns the tag part of the local address, or nil if not given.
    def tag
      local.tag
    end

    # Retuns any comments parsed from the local part of the email address.
    # This is retained for inspection after construction, even if it is
    # removed from the normalized email address.
    def comment
      local.comment
    end

    ############################################################################
    # Host Part (right of @) access
    # * host: Access full local part instance (alias: right)
    # * hostname: everything on the right of @
    # * provider: determined email service provider
    ############################################################################

    # Returns the host name, the part to the right of the @ sign.
    def host_name
      @host.host_name
    end
    alias_method :right, :host_name
    alias_method :hostname, :host_name

    # Returns the ESP (Email Service Provider) or ISP name derived
    # using the provider configuration rules.
    def provider
      @host.provider
    end

    ############################################################################
    # Address methods
    ############################################################################

    # Returns the string representation of the normalized email address.
    def normal
      if !@original
        @original
      elsif local.to_s.size == 0
        ""
      elsif host.to_s.size == 0
        local.to_s
      else
        "#{local}@#{host}"
      end
    end
    alias_method :to_s, :normal

    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} address=\"#{self}\">"
    end

    # Returns the canonical email address according to the provider
    # uniqueness rules. Usually, this downcases the address, removes
    # spaves and comments and tags, and any extraneous part of the address
    # not considered a unique account by the provider.
    def canonical
      c = local.canonical
      c += "@" + host.canonical if host.canonical && host.canonical > " "
      c
    end

    # True if the given address is already in it's canonical form.
    def canonical?
      canonical == to_s
    end

    # The base address is the mailbox, without tags, and host.
    def base
      mailbox + "@" + hostname
    end

    # Returns the redacted form of the address
    # This format is defined by this libaray, and may change as usage increases.
    # Takes either :sha1 (default) or :md5 as the argument
    def redact(digest = :sha1)
      raise "Unknown Digest type: #{digest}" unless %i[sha1 md5].include?(digest)
      return to_s if local.redacted?
      r = %({#{send(digest)}})
      r += "@" + host.to_s if host.to_s && host.to_s > " "
      r
    end

    # True if the address is already in the redacted state.
    def redacted?
      local.redacted?
    end

    # Returns the munged form of the address, by default "mailbox@domain.tld"
    # returns "ma*****@do*****".
    def munge
      [local.munge, host.munge].join("@")
    end

    # Returns and MD5 of the base address form. Some cross-system systems
    # use the email address MD5 instead of the actual address to refer to the
    # same shared user identity without exposing the actual address when it
    # is not known in common.
    def reference(form = :base)
      Digest::MD5.hexdigest(send(form))
    end
    alias_method :md5, :reference

    # This returns the SHA1 digest (in a hex string) of the base email
    # address. See #md5 for more background.
    def sha1(form = :base)
      Digest::SHA1.hexdigest((send(form) || "") + (@config[:sha1_secret] || ""))
    end

    def sha256(form = :base)
      Digest::SHA256.hexdigest((send(form) || "") + (@config[:sha256_secret] || ""))
    end

    #---------------------------------------------------------------------------
    # Comparisons & Matching
    #---------------------------------------------------------------------------

    # Equal matches the normalized version of each address. Use the Threequal to check
    # for match on canonical or redacted versions of addresses
    def ==(other)
      to_s == other.to_s
    end
    alias_method :eql?, :==
    alias_method :equal?, :==

    # Return the <=> or CMP comparison operator result (-1, 0, +1) on the comparison
    # of this addres with another, using the canonical or redacted forms.
    def same_as?(other_email)
      if other_email.is_a?(String)
        other_email = Address.new(other_email)
      end

      canonical == other_email.canonical ||
        redact == other_email.canonical ||
        canonical == other_email.redact
    end
    alias_method :include?, :same_as?

    # Return the <=> or CMP comparison operator result (-1, 0, +1) on the comparison
    # of this addres with another, using the normalized form.
    def <=>(other)
      to_s <=> other.to_s
    end

    # Address matches one of these Matcher rule patterns
    def matches?(*rules)
      rules.flatten!
      match = local.matches?(rules)
      match ||= host.matches?(rules)
      return match if match

      # Does "root@*.com" match "root@example.com" domain name
      rules.each do |r|
        if /.+@.+/.match?(r)
          return r if File.fnmatch?(r, to_s)
        end
      end
      false
    end

    #---------------------------------------------------------------------------
    # Validation
    #---------------------------------------------------------------------------

    # Returns true if this address is considered valid according to the format
    # configured for its provider, It test the normalized form.
    def valid?(options = {})
      @error = nil
      unless local.valid?
        return set_error local.error
      end
      unless host.valid?
        return set_error host.error_message
      end
      if @config[:address_size] && !@config[:address_size].include?(to_s.size)
        return set_error :exceeds_size
      end
      if @config[:address_validation].is_a?(Proc)
        unless @config[:address_validation].call(to_s)
          return set_error :not_allowed
        end
      else
        return false unless local.valid?
        return false unless host.valid?
      end
      true
    end

    # Connects to host to test if user can receive email. This should NOT be performed
    # as an email address check, but is provided to assist in problem resolution.
    # If you abuse this, you *could* be blocked by the ESP.
    #
    # NOTE: As of Ruby 3.1, Net::SMTP was moved from the standard library to the
    # 'net-smtp' gem. In order to avoid adding that dependency for this experimental
    # feature, please add the gem to your Gemfile and require it to use this feature.
    def connect
      smtp = Net::SMTP.new(host_name || ip_address)
      smtp.start(@config[:smtp_helo_name] || "localhost")
      smtp.mailfrom @config[:smtp_mail_from] || "postmaster@localhost"
      smtp.rcptto to_s
      # p [:connect]
      smtp.finish
      true
    rescue Net::SMTPUnknownError => e
      set_error(:address_unknown, e.to_s)
    rescue Net::SMTPFatalError => e
      set_error(:address_unknown, e.to_s)
    rescue SocketError => e
      set_error(:address_unknown, e.to_s)
    ensure
      if smtp&.started?
        smtp.finish
      end
      !!@error
    end

    def set_error(err, reason = nil)
      @error = err
      @reason = reason
      @error_message = Config.error_message(err, locale)
      false
    end

    attr_reader :error_message

    def error
      valid? ? nil : @error_message
    end
  end
end
