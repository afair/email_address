require 'digest/sha1'
require 'digest/md5'

module EmailAddress
  class Address

    def initialize(address)
      @address = address
      parse
    end

    def parse
      (_, local, host) = @address.match(/\A(.+)@(.+)/).to_a
      @host = EmailAddress::Host.new(host)
      @local = EmailAddress::Local.new(local||@address, @host)
    end

    def host
      @host
    end

    def local
      @local
    end

    def mailbox
      @local.mailbox
    end

    def host_name
      @host.host_name
    end

    def tag
      @local.tag
    end

    def comment
      @local.comment
    end

    def provider
      @host.provider
    end

    def to_s
      normalize
    end

    # The original email address in the request (unmodified).
    def original
      @address
    end

    def normalize
      [@local.normalize, @host.normalize].join('@')
    end

    def canonical
      [@local.canonical, @host.canonical].join('@')
    end

    def md5
      Digest::MD5.hexdigest(canonical)
    end

    def sha1
      Digest::SHA1.hexdigest(canonical)
    end

    # Obscure the address for storage. To protect the user's privacy,
    # use this when you don't want to store a real email, only a fingerprint.
    # Given the original address, you can match the original with this method.
    # This returns the SHA1 of the canonical address (no tags, no gmail dots)
    # at the original host. The host is part of the digest part, but also
    # retained for verification and domain maintenance.
    def obscure
      [sha1, @host.canonical].join('@')
    end

    def valid?(options={})
      EmailAddress::Validator.validate(self, options)
    end

    def errors(options={})
      v = EmailAddress::Validator.new(self, options)
      v.valid?
      v.errors
    end
  end
end
