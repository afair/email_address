# frozen_string_literal: true

module EmailAddress
  # Global configurations and for default/unknown providers. Settings are:
  #
  # * dns_lookup:         :mx, :a, :off
  #   Enables DNS lookup for validation by
  #   :mx       - DNS MX Record lookup
  #   :a        - DNS A Record lookup (as some domains don't specify an MX incorrectly)
  #   :off      - Do not perform DNS lookup (Test mode, network unavailable)
  #
  # * dns_timeout:        nil
  #   False, or a timeout in seconds. Timeout on the DNS lookup, after which it will fail.
  #
  # * sha1_secret         ""
  #   This application-level secret is appended to the email_address to compute
  #   the SHA1 Digest, making it unique to your application so it can't easily be
  #   discovered by comparing against a known list of email/sha1 pairs.
  #
  # * sha256_secret         ""
  #   This application-level secret is appended to the email_address to compute
  #   the SHA256 Digest, making it unique to your application so it can't easily be
  #   discovered by comparing against a known list of email/sha256 pairs.
  #
  # For local part configuration:
  # * local_downcase:     true
  #   Downcase the local part. You probably want this for uniqueness.
  #   RFC says local part is case insensitive, that's a bad part.
  #
  # * local_fix:          true,
  #   Make simple fixes when available, remove spaces, condense multiple punctuations
  #
  # * local_encoding:     :ascii, :unicode,
  #   Enable Unicode in local part. Most mail systems do not yet support this.
  #   You probably want to stay with ASCII for now.
  #
  # * local_parse:        nil, ->(local) { [mailbox, tag, comment] }
  #   Specify an optional lambda/Proc to parse the local part. It should return an
  #   array (tuple) of mailbox, tag, and comment.
  #
  # * local_format:       :conventional, :relaxed, :redacted, :standard, Proc
  #   :conventional       word ( puncuation{1} word )*
  #   :relaxed            alphanum ( allowed_characters)* alphanum
  #   :standard           RFC Compliant email addresses (anything goes!)
  #
  # * local_size:         1..64,
  #   A Range specifying the allowed size for mailbox + tags + comment
  #
  # * tag_separator:      nil, character (+)
  #   Nil, or a character used to split the tag from the mailbox
  #
  # For the mailbox (AKA account, role), without the tag
  # * mailbox_size:       1..64
  #   A Range specifying the allowed size for mailbox
  #
  # * mailbox_canonical:  nil, ->(mailbox) { mailbox }
  #   An optional lambda/Proc taking a mailbox name, returning a canonical
  #   version of it. (E.G.: gmail removes '.' characters)
  #
  # * mailbox_validator:  nil, ->(mailbox) { true }
  #   An optional lambda/Proc taking a mailbox name, returning true or false.
  #
  # * host_encoding:      :punycode,  :unicode,
  #   How to treat International Domain Names (IDN). Note that most mail and
  #   DNS systems do not support unicode, so punycode needs to be passed.
  #   :punycode           Convert Unicode names to punycode representation
  #   :unicode            Keep Unicode names as is.
  #
  # * host_validation:
  #   :mx                 Ensure host is configured with DNS MX records
  #   :a                  Ensure host is known to DNS (A Record)
  #   :syntax             Validate by syntax only, no Network verification
  #   :connect            Attempt host connection (not implemented, BAD!)
  #
  # * host_size:          1..253,
  #   A range specifying the size limit of the host part,
  #
  # * host_allow_ip:      false,
  #   Allow IP address format in host: [127.0.0.1], [IPv6:::1]
  #
  # * host_local:         false,
  #   Allow localhost, no domain, or local subdomains.
  #
  # * host_fqdn:          true
  #   Check if host name is FQDN
  #
  # * host_auto_append:   true
  #   Append localhost if host is missing
  #
  # * address_validation: :parts, :smtp, ->(address) { true }
  #   Address validation policy
  #   :parts              Validate local and host.
  #   :smtp               Validate via SMTP (not implemented, BAD!)
  #   A lambda/Proc taking the address string, returning true or false
  #
  # * address_size:       3..254,
  #   A range specifying the size limit of the complete address
  #
  # * address_fqdn_domain: nil || "domain.tld"
  #   Configure to complete the FQDN (Fully Qualified Domain Name)
  #   When host is blank, this value is used
  #   When host is computer name only, a dot and this is appended to get the FQDN
  #   You probably don't want this unless you have host-local email accounts
  #
  # For provider rules to match to domain names and Exchanger hosts
  # The value is an array of match tokens.
  # * host_match:         %w(.org example.com hotmail. user*@ sub.*.com)
  # * exchanger_match:    %w(google.com 127.0.0.1 10.9.8.0/24 ::1/64)
  #

  require "yaml"

  class Config
    @config = {
      dns_lookup: :mx, # :mx, :a, :off
      dns_timeout: nil,
      sha1_secret: "",
      sha256_secret: "",
      munge_string: "*****",

      local_downcase: true,
      local_fix: false,
      local_encoding: :ascii, # :ascii, :unicode,
      local_parse: nil, # nil, Proc
      local_format: :conventional, # :conventional, :relaxed, :redacted, :standard, Proc
      local_size: 1..64,
      tag_separator: "+", # nil, character
      mailbox_size: 1..64, # without tag
      mailbox_canonical: nil, # nil,  Proc
      mailbox_validator: nil, # nil,  Proc

      host_encoding: :punycode || :unicode,
      host_validation: :mx || :a || :connect || :syntax,
      host_size: 1..253,
      host_allow_ip: false,
      host_remove_spaces: false,
      host_local: false,
      host_fqdn: true,
      host_auto_append: true,
      host_timeout: 3,

      address_validation: :parts, # :parts, :smtp, Proc
      address_size: 3..254,
      address_fqdn_domain: nil # Fully Qualified Domain Name = [host].[domain.tld]
    }

    # 2018-04: AOL and Yahoo now under "oath.com", owned by Verizon. Keeping separate for now
    @providers = {
      aol: {
        host_match: %w[aol. compuserve. netscape. aim. cs.]
      },
      google: {
        host_match: %w[gmail.com googlemail.com],
        exchanger_match: %w[google.com googlemail.com],
        local_size: 3..64,
        local_private_size: 1..64, # When hostname not in host_match (private label)
        mailbox_canonical: ->(m) { m.delete(".") }
      },
      msn: {
        host_match: %w[msn. hotmail. outlook. live.],
        exchanger_match: %w[outlook.com],
        mailbox_validator: ->(m, t) { m =~ /\A\w[\-\w]*(?:\.[\-\w]+)*\z/i }
      },
      yahoo: {
        host_match: %w[yahoo. ymail. rocketmail.],
        exchanger_match: %w[yahoodns yahoo-inc]
      }
    }

    # Loads messages: {"en"=>{"email_address"=>{"invalid_address"=>"Invalid Email Address",...}}}
    # Rails/I18n gem: t(email_address.error, scope: "email_address")
    @errors = YAML.load_file(File.dirname(__FILE__) + "/messages.yaml")

    # Set multiple default configuration settings
    def self.configure(config = {})
      @config.merge!(config)
    end

    def self.setting(name, *value)
      name = name.to_sym
      @config[name] = value.first if value.size > 0
      @config[name]
    end

    # Returns the hash of Provider rules
    class << self
      attr_reader :providers
    end

    # Configure or lookup a provider by name.
    def self.provider(name, config = {})
      name = name.to_sym
      if config.size > 0
        @providers[name.to_sym] = config
      end
      @providers[name]
    end

    def self.error_message(name, locale = "en")
      @errors.dig(locale, "email_address", name.to_s) || name.to_s
    end

    # Customize your own error message text.
    def self.error_messages(hash = {}, locale = "en", *extra)
      hash = extra.first if extra.first.is_a? Hash

      @errors[locale] ||= {}
      @errors[locale]["email_address"] ||= {}

      unless hash.nil? || hash.empty?
        @errors[locale]["email_address"] = @errors[locale]["email_address"].merge(hash)
      end

      @errors[locale]["email_address"]
    end

    def self.all_settings(*configs)
      config = @config.clone
      configs.each { |c| config.merge!(c) }
      config
    end

    def initialize(overrides = {})
      @config = Config.all_settings(overrides)
    end

    def []=(setting, value)
      @config[setting.to_sym] = value
    end

    def [](setting)
      @config[setting.to_sym]
    end

    def configure(settings)
      @config = @config.merge(settings)
    end

    def to_h
      @config
    end
  end
end
