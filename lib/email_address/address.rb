module EmailAddress
  class Address

    def initialize(address)
      @address = address
      parse
    end

    def parse
      (_, local, host) = @address.match(/\A(.+)@(.+)/).to_a
      @local = EmailAddress::Local(local)
      @host = EmailAddress::Host(host)
    end
  end
end
