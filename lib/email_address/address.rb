require 'digest/sha1'
require 'digest/md5'

module EmailAddress
  class Address
    include Comparable

    # Given an email address of the form "local@hostname", this sets up the
    # instance, and initializes the address to the "normalized" format of the
    # address. The original string is available in the #original method.
    def initialize(email_address)
      @original     = email_address
      (local, host) = email_address.split('@', 2)
      @host         = EmailAddress::Host.new(host)
      @local        = EmailAddress::Local.new(local||@address, @host)
    end

    # Returns the Email::Address::Host to inspect the host name of the address
    def host
      @host
    end

    # Returns the EmailAddress::local to inspect the data to the left of the @
    # Use the #left method to access the full string
    def local
      @local
    end

    # Everything to the left of the @ in the address, called the local part.
    def left
      local.to_s
    end

    # Returns the mailbox portion of the local port, with no tags. Usually, this
    # can be considered the user account or role account names. Some systems
    # employ dynamic email addresses which don't have the same meaning.
    def mailbox
      @local.mailbox
    end

    # Returns the host name, the part to the right of the @ sign.
    def host_name
      @host.host_name
    end
    alias :right :host_name

    # Returns the tag part of the local address, or nil if not given.
    def tag
      @local.tag
    end

    # Retuns any comments parsed from the local part of the email address.
    # This is retained for inspection after construction, even if it is
    # removed from the normalized email address.
    def comment
      @local.comment
    end

    # Returns the ESP (Email Service Provider) or ISP name derived
    # using the provider configuration rules.
    def provider
      @host.provider
    end

    # Returns the string representation of the normalized email address.
    def to_s
      normalize
    end

    # The original email address in the request (unmodified).
    def original
      @original
    end

    # Returns the normailed email address according to the provider
    # and system normalization rules. Ususally this downcases the address,
    # removes spaces and comments, but includes any tags.
    def normalize
      [@local.normalize, @host.normalize].join('@')
    end

    # Returns the canonical email address according to the provider
    # uniqueness rules. Usually, this downcases the address, removes
    # spaves and comments and tags, and any extraneous part of the address
    # not considered a unique account by the provider.
    def canonical
      [@local.canonical, @host.canonical].join('@')
    end
    alias :uniq :canonical

    # Returns and MD5 of the canonical address form. Some cross-system systems
    # use the email address MD5 instead of the actual address to refer to the
    # same shared user identity without exposing the actual address when it
    # is not known in common.
    def md5
      Digest::MD5.hexdigest(canonical)
    end

    # This returns the SHA1 digest (in a hex string) of the canonical email
    # address. See #md5 for more background.
    def sha1
      Digest::SHA1.hexdigest(canonical)
    end

    # Equal matches the normalized version of each address. Use the Threequal to check
    # for match on canonical or redacted versions of addresses
    def ==(other_email)
      normalize == other_email.normalize
    end
    alias :eql? :==
    alias :equal? :==

    # Return the <=> or CMP comparison operator result (-1, 0, +1) on the comparison
    # of this addres with another, using the canonical or redacted forms.
    def same_as?(other_email)
      canonical == other_email.canonical ||
        redact == other_email.canonical || canonical == other_email.redact
    end
    alias :include? :same_as?

    # Return the <=> or CMP comparison operator result (-1, 0, +1) on the comparison
    # of this addres with another, using the normalized form.
    def <=>(other_email)
      normalize <=> other_email.normalize
    end

    # Redact the address for storage. To protect the user's privacy,
    # use this when you don't want to store a real email, only a fingerprint.
    # Given the original address, you can match the original with this method.
    # This returns the SHA1 of the canonical address (no tags, no gmail dots)
    # at the original host. The host is part of the digest part, but also
    # retained for verification and domain maintenance.
    def redact
      [sha1, @host.canonical].join('@')
    end

    def redacted?
      @local.to_s =~ /\A[0-9a-f]{40}\z/ ? true : false
    end

    # Returns true if this address is considered valid according to the format
    # configured for its provider, It test the normalized form.
    def valid?(options={})
      EmailAddress::Validator.validate(self, options)
    end

    # Returns an array of error messages generated from the validation process via
    # the #valid? method.
    def errors(options={})
      v = EmailAddress::Validator.new(self, options)
      v.valid?
      v.errors
    end
  end
end
