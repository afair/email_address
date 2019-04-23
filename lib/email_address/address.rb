# frozen_string_literal: true

require 'digest/sha1'
require 'digest/md5'

module CheckEmailAddress
  # Implements the Email Address container, which hold the Local
  # (CheckEmailAddress::Local) and Host (Email::AddressHost) parts.
  class Address
    include Comparable
    include CheckEmailAddress::Rewriter

    attr_accessor :original, :local, :host, :config, :reason

    CONVENTIONAL_REGEX = /\A#{::CheckEmailAddress::Local::CONVENTIONAL_MAILBOX_WITHIN}
                           @#{::CheckEmailAddress::Host::DNS_HOST_REGEX}\z/x
    STANDARD_REGEX     = /\A#{::CheckEmailAddress::Local::STANDARD_LOCAL_WITHIN}
                           @#{::CheckEmailAddress::Host::DNS_HOST_REGEX}\z/x
    RELAXED_REGEX      = /\A#{::CheckEmailAddress::Local::RELAXED_MAILBOX_WITHIN}
                           @#{::CheckEmailAddress::Host::DNS_HOST_REGEX}\z/x

    # Given an email address of the form "local@hostname", this sets up the
    # instance, and initializes the address to the "normalized" format of the
    # address. The original string is available in the #original method.
    def initialize(email_address, config={})
      @config        = config # This needs refactoring!
      email_address  = (email_address || "").strip
      @original      = email_address
      email_address  = parse_rewritten(email_address) unless config[:skip_rewrite]
      local, host    = CheckEmailAddress::Address.split_local_host(email_address)

      @host         = CheckEmailAddress::Host.new(host, config)
      @config       = @host.config
      @local        = CheckEmailAddress::Local.new(local, @config, @host)
      @error        = @error_message = nil
    end

    # Given an email address, this returns an array of [local, host] parts
    def self.split_local_host(email)
      if lh = email.match(/(.+)@(.+)/)
        lh.to_a[1,2]
      else
        [email, '']
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
      self.local.to_s
    end

    # Returns the mailbox portion of the local port, with no tags. Usually, this
    # can be considered the user account or role account names. Some systems
    # employ dynamic email addresses which don't have the same meaning.
    def mailbox
      self.local.mailbox
    end

    # Returns the tag part of the local address, or nil if not given.
    def tag
      self.local.tag
    end

    # Retuns any comments parsed from the local part of the email address.
    # This is retained for inspection after construction, even if it is
    # removed from the normalized email address.
    def comment
      self.local.comment
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
    alias :right :host_name
    alias :hostname :host_name

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
      elsif self.local.to_s.size == 0
        ""
      elsif self.host.to_s.size == 0
        self.local.to_s
      else
        "#{self.local.to_s}@#{self.host.to_s}"
      end
    end
    alias :to_s :normal

    def inspect
      "#<CheckEmailAddress::Address:0x#{self.object_id.to_s(16)} address=\"#{self.to_s}\">"
    end

    # Returns the canonical email address according to the provider
    # uniqueness rules. Usually, this downcases the address, removes
    # spaves and comments and tags, and any extraneous part of the address
    # not considered a unique account by the provider.
    def canonical
      c = self.local.canonical
      c += "@" + self.host.canonical if self.host.canonical && self.host.canonical > " "
      c
    end

    # True if the given address is already in it's canonical form.
    def canonical?
      self.canonical == self.to_s
    end

    # The base address is the mailbox, without tags, and host.
    def base
      self.mailbox + "@" + self.hostname
    end

    # Returns the redacted form of the address
    # This format is defined by this libaray, and may change as usage increases.
    # Takes either :sha1 (default) or :md5 as the argument
    def redact(digest=:sha1)
      raise "Unknown Digest type: #{digest}" unless %i(sha1 md5).include?(digest)
      return self.to_s if self.local.redacted?
      r = %Q({#{send(digest)}})
      r += "@" + self.host.to_s if self.host.to_s && self.host.to_s > " "
      r
    end

    # True if the address is already in the redacted state.
    def redacted?
      self.local.redacted?
    end

    # Returns the munged form of the address, by default "mailbox@domain.tld"
    # returns "ma*****@do*****".
    def munge
      [self.local.munge, self.host.munge].join("@")
    end

    # Returns and MD5 of the canonical address form. Some cross-system systems
    # use the email address MD5 instead of the actual address to refer to the
    # same shared user identity without exposing the actual address when it
    # is not known in common.
    def reference(form=:base)
      Digest::MD5.hexdigest(self.send(form))
    end
    alias :md5 :reference

    # This returns the SHA1 digest (in a hex string) of the canonical email
    # address. See #md5 for more background.
    def sha1(form=:base)
      Digest::SHA1.hexdigest((self.send(form)||"") + (@config[:sha1_secret]||""))
    end

    #---------------------------------------------------------------------------
    # Comparisons & Matching
    #---------------------------------------------------------------------------

    # Equal matches the normalized version of each address. Use the Threequal to check
    # for match on canonical or redacted versions of addresses
    def ==(other_email)
      self.to_s == other_email.to_s
    end
    alias :eql? :==
    alias :equal? :==

    # Return the <=> or CMP comparison operator result (-1, 0, +1) on the comparison
    # of this addres with another, using the canonical or redacted forms.
    def same_as?(other_email)
      if other_email.is_a?(String)
        other_email = CheckEmailAddress::Address.new(other_email)
      end

      self.canonical   == other_email.canonical ||
        self.redact    == other_email.canonical ||
        self.canonical == other_email.redact
    end
    alias :include? :same_as?

    # Return the <=> or CMP comparison operator result (-1, 0, +1) on the comparison
    # of this addres with another, using the normalized form.
    def <=>(other_email)
      self.to_s <=> other_email.to_s
    end

    # Address matches one of these Matcher rule patterns
    def matches?(*rules)
      rules.flatten!
      match   = self.local.matches?(rules)
      match ||= self.host.matches?(rules)
      return match if match

      # Does "root@*.com" match "root@example.com" domain name
      rules.each do |r|
        if r =~ /.+@.+/
          return r if File.fnmatch?(r, self.to_s)
        end
      end
      false
    end

    #---------------------------------------------------------------------------
    # Validation
    #---------------------------------------------------------------------------

    # Returns true if this address is considered valid according to the format
    # configured for its provider, It test the normalized form.
    def valid?(options={})
      @error = nil
      unless self.local.valid?
        return set_error self.local.error
      end
      unless self.host.valid?
        return set_error self.host.error_message
      end
      if @config[:address_size] && !@config[:address_size].include?(self.to_s.size)
        return set_error :exceeds_size
      end
      if @config[:address_validation].is_a?(Proc)
        unless @config[:address_validation].call(self.to_s)
          return set_error :not_allowed
        end
      else
        return false unless self.local.valid?
        return false unless self.host.valid?
      end
      if @config[:address_validation] == :smtp

      end
      true
    end

    # Connects to host to test if user can receive email. This should NOT be performed
    # as an email address check, but is provided to assist in problem resolution.
    # If you abuse this, you *could* be blocked by the ESP.
    def connect
      begin
        smtp = Net::SMTP.new(self.host_name || self.ip_address)
        smtp.start(@config[:smtp_helo_name] || 'localhost')
        smtp.mailfrom @config[:smtp_mail_from] || 'postmaster@localhost'
        smtp.rcptto self.to_s
        #p [:connect]
        smtp.finish
        true
      rescue Net::SMTPUnknownError => e
        set_error(:address_unknown, e.to_s)
      rescue Net::SMTPFatalError => e
        set_error(:address_unknown, e.to_s)
      rescue SocketError => e
        set_error(:address_unknown, e.to_s)
      ensure
        if smtp && smtp.started?
          smtp.finish
        end
        !!@error
      end
    end

    def set_error(err, reason=nil)
      @error = err
      @reason= reason
      @error_message = CheckEmailAddress::Config.error_message(err)
      false
    end

    def error_message
      @error_message
    end

    def error
      self.valid? ? nil : @error_message
    end

  end
end
