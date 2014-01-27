module EmailAddress
  ##############################################################################
  # DomainMatcher - Matches a domain to a set of patterns
  # 
  # Match Patterns
  #   hostname      sub.domain.tld
  #   domain        domain.tld
  #   registration  domain 
  #   tld           .tld, .domain.tld
  ##############################################################################
  class DomainMatcher
    attr_reader :host_name, :parts, :domain_name, :registration_name,
                :tld, :subdomains, :ip_address

    def self.matches?(domain, rule)
      DomainMatcher.new(domain, rule).matches?
    end

    def initialize(host_name, rule=nil)
      @host_name = host_name.downcase
      @host = EmailAddress::Host.new(@host_name)
      @rule = rule
      matches?
    end

    def matches?(rule=nil)
      rule ||= @rule
      case rule
      when String
        rule_matches?(rule)
      when Array
        list_matches?(rule)
      else
        false
      end
    end

    def rule_matches?(rule)
      rule.downcase!
      @host_name == rule || registration_name_matches?(rule) ||
        domain_matches?(rule) || tld_matches?(rule)
    end

    def list_matches?(list)
      list.each {|rule| return true if rule_matches?(rule) }
      false
    end

    # Does "sub.example.com" match "example" registration name
    def registration_name_matches?(rule)
      rule.match(/\A(\w+)\z/) && @host.registration_name == rule.downcase ? true : false
    end

    # Does "sub.example.com" match "example.com" domain name
    def domain_matches?(rule)
      rule.match(/\A[^\.]+\.[^\.]+\z/) && @host.domain_name == rule.downcase ? true : false
    end

    # Does "sub.example.com" match ".com" and ".example.com" top level names?
    def tld_matches?(rule)
      rule.match(/\A\..+\z/) && 
        ( @host_name[-rule.size, rule.size] == rule.downcase || ".#{@host_name}" == rule) \
        ? true : false
    end

    # Does an IP of mail exchanger for "sub.example.com" match "xxx.xx.xx.xx/xx"?
    def ip_cidr_matches?(rule)
      return false unless rule.match(/\A\d.+\/\d+\z/) && @host.exchanger
      @host.exchanger.in_cidr?(r) ? true : false
    end

    #def provider_matches?(rule)
    #  if rule.downcase.match(/\A\:(\w+)\z/)
    #    p ["PROVIDER", rule, @host_name, provider_by_domain ]
    #    prov = provider_by_domain
    #    prov && prov == $1 ? true : false
    #  end
    #end

    ## Match only by
    #def provider_by_domain
    #  base = EmailAddress::Config.providers[:default]
    #  EmailAddress::Config.providers.first do |name, defn|
    #    defn = base.merge(defn)
    #    return name if matches?(defn[:domains])
    #  end
    #  nil
    #end
  end
end
