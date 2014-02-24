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
      @local = EmailAddress::Local.new(local, @host.provider)
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

    def archive
      [sha1, @host.canonical].join('@')
    end

    def valid?(options={})
      EmailAddress::Validator.validate(self, options)
    end
  end
end
