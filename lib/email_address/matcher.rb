module EmailAddress
  ##############################################################################
  # Matcher - Allows matching of an email address against a list of matching
  #           tokens.
  #
  # Match Patterns
  #   * Top-Level-Domain:         .org
  #   * Domain Name:              example.com
  #   * Registration Name:        hotmail.   (matches any TLD)
  #   * Domain Glob:              *.exampl?.com
  #   * Provider Name:            google
  #   * Mailbox Name or Glob:     user00*@
  #   * Address or Glob:          postmaster@domain*.com
  #   * Provider or Registration: msn (?? Possible combo for either match?)
  #
  # Usage:
  #   m = EmailAddress::Matcher.new(".org example.com hotmail. google user*@ root@*.com")
  #   m.include?("pat@example.com")
  ##############################################################################

  class Matcher
    attr_reader :rules, :email

    def self.matches?(rule, email)
      EmailAddress::Matcher.new(rule).matches?(email)
    end

    def initialize(rules=[], empty_rules_return=false)
      self.rules = rules
      @empty_rules_return = empty_rules_return
    end

    def rules=(r)
      @rules = r.is_a?(Array) ? r : r.split(/\s+/)
      @rules = @rules.map(&:downcase)
    end

    def email=(e)
      if e.is_a?(EmailAddress::Address)
        @email            = e.normalize
        @mailbox          = e.mailbox
        @domain           = e.host.name
        @domain_parts     = e.host.parts
        @provider         = e.provider
      elsif e.is_a?(Hash)
        @email            = e[:email]
        @mailbox          = e[:mailbox]
        @domain           = e[:domain]
        @domain_parts     = EmailAddress::DomainParser.new(@domain).parts
        @provider         = e[:provider]
      else
        @email            = e.downcase
        @mailbox, @domain = @email.split('@')
        @domain_parts     = EmailAddress::DomainParser.new(@domain).parts
        @provider         = nil
      end
    end

    # Takes a email address string, returns true if it matches a rule
    def include?(email_address)
      self.email = email_address
      return @empty_rules_return if @rules.empty?
      @rules.each do |rule|
        return true if registration_name_matches?(rule)
        return true if tld_matches?(rule)
        return true if provider_matches?(rule)
        return true if domain_matches?(rule)
        return true if email_matches?(rule)
        #return true if ip_cidr_matches?(rule)
      end
      false
    end

    # Does "example." match any tld?
    def registration_name_matches?(rule)
      @domain_parts[:registration_name]+'.' == rule ? true : false
    end

    # Does "sub.example.com" match ".com" and ".example.com" top level names?
    def tld_matches?(rule)
      rule.match(/\A\..+\z/) &&
        ( @domain[-rule.size, rule.size] == rule || ".#{@domain}" == rule) \
        ? true : false
    end

    def provider_matches?(rule)
      rule =~ /\A[\w\-]*\z/ && self.provider == rule.to_sym
    end

    def provider
      @provider ||= EmailAddress::Config.providers.each do |prov, defn|
        if defn.has_key?(:domains) && !defn[:domains].empty?
          defn[:domains].each do |d|
            if domain_matches?(d) || registration_name_matches?(d)
              return @provider = prov
            end
          end
        end
      end
      @provider ||= :unknown
    end

    # Does domain == rule or glob matches?
    def domain_matches?(rule, domain=@domain)
      return false if rule.include?("@")
      domain == rule || File.fnmatch?(rule, domain)
    end

    # Does "root@*.com" match "root@example.com" domain name
    def email_matches?(rule)
      return false unless rule.include?("@")
      @email == rule || File.fnmatch?(rule, @email)
    end

    # Does an IP of mail exchanger for "sub.example.com" match "xxx.xx.xx.xx/xx"?
    def ip_cidr_matches?(rule)
      return false unless rule.match(/\A\d.+\/\d+\z/) && @host.exchanger
      @host.exchanger.in_cidr?(r) ? true : false
    end

  end
end
