module EmailAddress
  # Global configurations and for default/unknown providers. Settings are:
  #
  # * dns_lookup:         :mx, :a, :off
  #   Enables DNS lookup for validation by
  #   :mx       - DNS MX Record lookup
  #   :a        - DNS A Record lookup (as some domains don't specify an MX incorrectly)
  #   :off      - Do not perform DNS lookup (Test mode, network unavailable)
  #
  # * sha1_secret         ""
  #   This application-level secret is appended to the email_address to compute
  #   the SHA1 Digest, making it unique to your application so it can't easily be
  #   discovered by comparing against a known list of email/sha1 pairs.
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
  # * address_validation: :parts, :smtp, ->(address) { true }
  #   Address validation policy
  #   :parts              Validate local and host.
  #   :smtp               Validate via SMTP (not implemented, BAD!)
  #   A lambda/Proc taking the address string, returning true or false
  #
  # * address_size:       3..254,
  #   A range specifying the size limit of the complete address
  #
  # * address_local:      false,
  #   Allow localhost, no domain, or local subdomains.
  #
  # For provider rules to match to domain names and Exchanger hosts
  # The value is an array of match tokens.
  # * host_match:         %w(.org example.com hotmail. user*@ sub.*.com)
  # * exchanger_match:    %w(google.com 127.0.0.1 10.9.8.0/24 ::1/64)
  #

  class Config
    @config = {
      dns_lookup:         :mx,  # :mx, :a, :off
      sha1_secret:        "",
      munge_string:       "*****",

      local_downcase:     true,
      local_fix:          true,
      local_encoding:     :ascii, # :ascii, :unicode,
      local_parse:        nil,   # nil, Proc
      local_format:       :conventional, # :conventional, :relaxed, :redacted, :standard, Proc
      local_size:         1..64,
      tag_separator:      '+', # nil, character
      mailbox_size:       1..64, # without tag
      mailbox_canonical:  nil, # nil,  Proc
      mailbox_validator:  nil, # nil,  Proc

      host_encoding:      :punycode || :unicode,
      host_validation:    :mx || :a || :connect,
      host_size:          1..253,
      host_allow_ip:      false,

      address_validation: :parts, # :parts, :smtp, Proc
      address_size:       3..254,
      address_localhost:  false,
    }

    @providers = {
      aol: {
        host_match:       %w(aol. compuserve. netscape. aim. cs.),
      },
      google: {
        host_match:       %w(gmail.com googlemail.com),
        exchanger_match:  %w(google.com),
        local_size:       5..64,
        mailbox_canonical: ->(m) {m.gsub('.','')},
      },
      msn: {
        host_match:       %w(msn. hotmail. outlook. live.),
        mailbox_validator: ->(m,t) { m =~ /\A[a-z0-9][\.\-a-z0-9]{5,29}\z/i},
      },
      yahoo: {
        host_match:       %w(yahoo. ymail. rocketmail.),
        exchanger_match:  %w(yahoodns yahoo-inc),
      },
    }

    @errors = {
      invalid_address:    "Invalid Email Address",
      invalid_mailbox:    "Invalid Recipient/Mailbox",
      invalid_host:       "Invalid Host/Domain Name",
      exceeds_size:       "Address too long",
      not_allowed:        "Address is not allowed",
      incomplete_domain:  "Domain name is incomplete",
    }

    # Set multiple default configuration settings
    def self.configure(config={})
      @config.merge!(config)
    end

    def self.setting(name, *value)
      name = name.to_sym
      @config[name] = value.first if value.size > 0
      @config[name]
    end

    # Returns the hash of Provider rules
    def self.providers
      @providers
    end

    # Configure or lookup a provider by name.
    def self.provider(name, config={})
      name = name.to_sym
      if config.size > 0
        @providers[name] ||= @config.clone
        @providers[name].merge!(config)
      end
      @providers[name]
    end

    # Customize your own error message text.
    def self.error_messages(hash=nil)
      @errors = @errors.merge(hash) if hash
      @errors
    end

    def self.all_settings(*configs)
      config = @config.clone
      configs.each {|c| config.merge!(c) }
      config
    end
  end
end
