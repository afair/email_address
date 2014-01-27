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
      @host.to_s
    end

    def local
      @local.to_s
    end

    def provider
      @host.provider
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
      EmailAddress::Vaildator.validate(@local, @host, options)
    end
  end
end
