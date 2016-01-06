require 'digest/sha1'
require 'digest/md5'

module EmailAddress
  class Address
    include Comparable
    attr_accessor :original, :local, :host, :config, :error

    # Given an email address of the form "local@hostname", this sets up the
    # instance, and initializes the address to the "normalized" format of the
    # address. The original string is available in the #original method.
    def initialize(email_address, config={})
      email_address.strip! if email_address
      @original      = email_address
      email_address||= ""
      if lh = email_address.match(/(.+)@(.+)/)
        (_, local, host) = lh.to_a
      else
        (local, host)    = [email_address, '']
      end
      @host         = EmailAddress::Host.new(host, config)
      @config       = @host.config
      @local        = EmailAddress::Local.new(local, @config)
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
    def to_s
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

    def inspect
      "#<EmailAddress::Address:0x#{self.object_id.to_s(16)} address=\"#{self.to_s}\">"
    end

    #---------------------------------------------------------------------------
    # Canonical
    # Returns the canonical email address according to the provider
    # uniqueness rules. Usually, this downcases the address, removes
    # spaves and comments and tags, and any extraneous part of the address
    # not considered a unique account by the provider.
    #---------------------------------------------------------------------------
    def canonical
      [self.local.canonical, @host.canonical].join('@')
    end

    def canonical?
      self.canonical == self.to_s
    end

    #---------------------------------------------------------------------------
    # Returns the redacted form of the address
    # This format is defined by this libaray, and may change as usage increases.
    #---------------------------------------------------------------------------
    def redact
      return self.to_s if self.local.redacted?
      %Q({#{self.sha1}}@#{self.host.to_s})
    end

    def redacted?
      self.local.redacted?
    end

    def munge
      [self.local.munge, self.host.munge].join("@")
    end

    #---------------------------------------------------------------------------
    # Reference (MD5, SHA1)
    # Returns and MD5 of the canonical address form. Some cross-system systems
    # use the email address MD5 instead of the actual address to refer to the
    # same shared user identity without exposing the actual address when it
    # is not known in common.
    #---------------------------------------------------------------------------

    def reference
      Digest::MD5.hexdigest(self.canonical)
    end
    alias :md5 :reference

    # This returns the SHA1 digest (in a hex string) of the canonical email
    # address. See #md5 for more background.
    def sha1
      Digest::SHA1.hexdigest(canonical + @config[:sha1_secret])
    end

    #---------------------------------------------------------------------------
    # Comparisons & Matching
    # Equal matches the normalized version of each address. Use the Threequal to check
    # for match on canonical or redacted versions of addresses
    #---------------------------------------------------------------------------

    def ==(other_email)
      self.to_s == other_email.to_s
    end
    alias :eql? :==
    alias :equal? :==

    # Return the <=> or CMP comparison operator result (-1, 0, +1) on the comparison
    # of this addres with another, using the canonical or redacted forms.
    def same_as?(other_email)
      if other_email.is_a?(String)
        other_email = EmailAddress::Address.new(other_email)
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
    # Returns true if this address is considered valid according to the format
    # configured for its provider, It test the normalized form.
    #---------------------------------------------------------------------------
    def valid?(options={})
      self.error = nil
      unless self.local.valid?
        self.error = "Invalid Mailbox"
        return false
      end
      unless self.host.valid?
        self.error = "Invalid Host"
        return false
      end
      if @config[:address_size] && !@config[:address_size].include?(self.to_s.size)
        self.error = "Exceeds size"
        return false
      end
      if @config[:address_validation].is_a?(Proc)
        unless @config[:address_validation].call(self.to_s)
          self.error = "Not allowed"
          return false
        end
      else
        return false unless self.local.valid?
        return false unless self.host.valid?
      end
      if !@config[:address_local] && !self.hostname.include?(".")
        self.error = "Incomplete Domain"
        return false
      end
      true
    end

    def error
      self.valid? ? nil : @error
    end

  end
end
