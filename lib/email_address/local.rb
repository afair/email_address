# frozen_string_literal: true

module EmailAddress
  ##############################################################################
  # EmailAddress Local part consists of
  # - comments
  # - mailbox
  # - tag
  #-----------------------------------------------------------------------------
  # Parsing id provider-dependent, but RFC allows:
  # Chars: A-Z a-z 0-9 . ! # $ % ' * + - / = ? ^G _ { | } ~
  # Quoted: space ( ) , : ; < > @ [ ]
  # Quoted-Backslash-Escaped: \ "
  # Quote local part or dot-separated sub-parts x."y".z
  # RFC-5321 warns "a host that expects to receive mail SHOULD avoid defining mailboxes
  #     where the Local-part requires (or uses) the Quoted-string form".
  # (comment)mailbox | mailbox(comment)
  # . can not appear at beginning or end, or appear consecutively
  # 8-bit/UTF-8: allowed but mail-system defined
  # RFC 5321 also warns that "a host that expects to receive mail SHOULD avoid
  #   defining mailboxes where the Local-part requires (or uses) the Quoted-string form".
  # Postmaster: must always be case-insensitive
  # Case: sensitive, but usually treated as equivalent
  # Local Parts: comment, mailbox tag
  # Length: up to 64 characters
  # Note: gmail does allow ".." against RFC because they are ignored. This will
  #   be fixed by collapsing consecutive punctuation in conventional formats,
  #   and consider them typos.
  ##############################################################################
  # RFC5322 Rules (Oct 2008):
  #---------------------------------------------------------------------------
  # addr-spec       =   local-part "@" domain
  # local-part      =   dot-atom / quoted-string / obs-local-part
  # domain          =   dot-atom / domain-literal / obs-domain
  # domain-literal  =   [CFWS] "[" *([FWS] dtext) [FWS] "]" [CFWS]
  # dtext           =   %d33-90 /          ; Printable US-ASCII
  #                     %d94-126 /         ;  characters not including
  #                     obs-dtext          ;  "[", "]", or "\"
  # atext           =   ALPHA / DIGIT /    ; Printable US-ASCII
  #                        "!" / "#" /        ;  characters not including
  #                        "$" / "%" /        ;  specials.  Used for atoms.
  #                        "&" / "'" /
  #                        "*" / "+" /
  #                        "-" / "/" /
  #                        "=" / "?" /
  #                        "^" / "_" /
  #                        "`" / "{" /
  #                        "|" / "}" /
  #                        "~"
  # atom            =   [CFWS] 1*atext [CFWS]
  # dot-atom-text   =   1*atext *("." 1*atext)
  # dot-atom        =   [CFWS] dot-atom-text [CFWS]
  # specials        =   "(" / ")" /        ; Special characters that do
  #                        "<" / ">" /        ;  not appear in atext
  #                        "[" / "]" /
  #                        ":" / ";" /
  #                        "@" / "\" /
  #                        "," / "." /
  #                        DQUOTE
  # qtext           =   %d33 /             ; Printable US-ASCII
  #                        %d35-91 /          ;  characters not including
  #                        %d93-126 /         ;  "\" or the quote character
  #                        obs-qtext
  # qcontent        =   qtext / quoted-pair
  # quoted-string   =   [CFWS]
  #                        DQUOTE *([FWS] qcontent) [FWS] DQUOTE
  #                        [CFWS]
  ############################################################################
  class Local
    attr_reader :local
    attr_accessor :mailbox, :comment, :tag, :config, :original
    attr_accessor :syntax, :locale

    # RFC-2142: MAILBOX NAMES FOR COMMON SERVICES, ROLES AND FUNCTIONS
    BUSINESS_MAILBOXES = %w[info marketing sales support]
    NETWORK_MAILBOXES = %w[abuse noc security]
    SERVICE_MAILBOXES = %w[postmaster hostmaster usenet news webmaster www uucp ftp]
    SYSTEM_MAILBOXES = %w[help mailer-daemon root] # Not from RFC-2142
    ROLE_MAILBOXES = %w[staff office orders billing careers jobs] # Not from RFC-2142
    SPECIAL_MAILBOXES = BUSINESS_MAILBOXES + NETWORK_MAILBOXES + SERVICE_MAILBOXES +
      SYSTEM_MAILBOXES + ROLE_MAILBOXES
    STANDARD_MAX_SIZE = 64

    # Conventional : word([.-+'_]word)*
    CONVENTIONAL_MAILBOX_REGEX = /\A [\p{L}\p{N}_]+ (?: [.\-+'_] [\p{L}\p{N}_]+ )* \z/x
    CONVENTIONAL_MAILBOX_WITHIN = /[\p{L}\p{N}_]+ (?: [.\-+'_] [\p{L}\p{N}_]+ )*/x

    # Relaxed: same characters, relaxed order
    RELAXED_MAILBOX_WITHIN = /[\p{L}\p{N}_]+ (?: [.\-+'_]+ [\p{L}\p{N}_]+ )*/x
    RELAXED_MAILBOX_REGEX = /\A [\p{L}\p{N}_]+ (?: [.\-+'_]+ [\p{L}\p{N}_]+ )* \z/x

    # RFC5322 Token: token."token".token (dot-separated tokens)
    #   Quoted Token can also have: SPACE \" \\ ( ) , : ; < > @ [ \ ] .
    STANDARD_LOCAL_WITHIN = /
      (?: [\p{L}\p{N}!\#$%&'*+\-\/=?\^_`{|}~()]+
        | " (?: \\[" \\] | [\x20-\x21\x23-\x2F\x3A-\x40\x5B\x5D-\x60\x7B-\x7E\p{L}\p{N}] )+ " )
      (?: \.  (?: [\p{L}\p{N}!\#$%&'*+\-\/=?\^_`{|}~()]+
              | " (?: \\[" \\] | [\x20-\x21\x23-\x2F\x3A-\x40\x5B\x5D-\x60\x7B-\x7E\p{L}\p{N}] )+ " ) )* /x

    STANDARD_LOCAL_REGEX = /\A #{STANDARD_LOCAL_WITHIN} \z/x

    REDACTED_REGEX = /\A \{ [0-9a-f]{40} \} \z/x # {sha1}

    CONVENTIONAL_TAG_REGEX = #  AZaz09_!'+-/=
      %r{^([\w!'+\-/=.]+)$}i
    RELAXED_TAG_REGEX = #  AZaz09_!#$%&'*+-/=?^`{|}~
      %r/^([\w.!\#$%&'*+\-\/=?\^`{|}~]+)$/i

    def initialize(local, config = {}, host = nil, locale = "en")
      @config = config.is_a?(Hash) ? Config.new(config) : config
      self.local = local
      @host = host
      @locale = locale
      @error = @error_message = nil
    end

    def local=(raw)
      self.original = raw
      raw.downcase! if @config[:local_downcase].nil? || @config[:local_downcase]
      @local = raw

      if @config[:local_parse].is_a?(Proc)
        self.mailbox, self.tag, self.comment = @config[:local_parse].call(raw)
      else
        self.mailbox, self.tag, self.comment = parse(raw)
      end

      self.format
    end

    def parse(raw)
      if raw =~ /\A"(.*)"\z/ # Quoted
        raw = $1
        raw = raw.gsub(/\\(.)/, '\1') # Unescape
      elsif @config[:local_fix] && @config[:local_format] != :standard
        raw = raw.delete(" ")
        raw = raw.tr(",", ".")
        # raw.gsub!(/([^\p{L}\p{N}]{2,10})/) {|s| s[0] } # Stutter punctuation typo
      end
      raw, comment = parse_comment(raw)
      mailbox, tag = parse_tag(raw)
      mailbox ||= ""
      [mailbox, tag, comment]
    end

    # "(comment)mailbox" or "mailbox(comment)", only one comment
    # RFC Doesn't say what to do if 2 comments occur, so last wins
    def parse_comment(raw)
      c = nil
      if raw =~ /\A\((.+?)\)(.+)\z/
        c, raw = [$2, $1]
      end
      if raw =~ /\A(.+)\((.+?)\)\z/
        raw, c = [$1, $2]
      end
      [raw, c]
    end

    def parse_tag(raw)
      separator = @config[:tag_separator] ||= "+"

      return raw if raw.start_with? separator

      raw.split(separator, 2)
    end

    # True if the the value contains only Latin characters (7-bit ASCII)
    def ascii?
      !unicode?
    end

    # True if the the value contains non-Latin Unicde characters
    def unicode?
      /[^\p{InBasicLatin}]/.match?(local)
    end

    # Returns true if the value matches the Redacted format
    def redacted?
      REDACTED_REGEX.match?(local)
    end

    # Returns true if the value matches the Redacted format
    def self.redacted?(local)
      REDACTED_REGEX.match?(local)
    end

    # Is the address for a common system or business role account?
    def special?
      SPECIAL_MAILBOXES.include?(mailbox)
    end

    def to_s
      self.format
    end

    # Builds the local string according to configurations
    def format(form = @config[:local_format] || :conventional)
      if @config[:local_format].is_a?(Proc)
        @config[:local_format].call(self)
      elsif form == :conventional
        conventional
      elsif form == :canonical
        canonical
      elsif form == :relaxed
        relax
      elsif form == :standard
        standard
      end
    end

    # Returns a conventional form of the address
    def conventional
      if tag
        [mailbox, tag].join(@config[:tag_separator])
      else
        mailbox
      end
    end

    # Returns a canonical form of the address
    def canonical
      if @config[:mailbox_canonical]
        @config[:mailbox_canonical].call(mailbox)
      else
        mailbox.downcase
      end
    end

    # Relaxed format: mailbox and tag, no comment, no extended character set
    def relax
      form = mailbox
      form += @config[:tag_separator] + tag if tag
      form.gsub(/[ "(),:<>@\[\]\\]/, "")
    end

    # Returns a normalized version of the standard address parts.
    def standard
      form = mailbox
      form += @config[:tag_separator] + tag if tag
      form += "(" + comment + ")" if comment
      form = form.gsub(/([\\"])/, '\\\1') # Escape \ and "
      if /[ "(),:<>@\[\\\]]/.match?(form) # Space and "(),:;<>@[\]
        form = %("#{form}")
      end
      form
    end

    # Sets the part to be the conventional form
    def conventional!
      self.local = conventional
    end

    # Sets the part to be the canonical form
    def canonical!
      self.local = canonical
    end

    # Dropps unusual  parts of Standard form to form a relaxed version.
    def relax!
      self.local = relax
    end

    # Returns the munged form of the address, like "ma*****"
    def munge
      to_s.sub(/\A(.{1,2}).*/) { |m| $1 + @config[:munge_string] }
    end

    # Mailbox with trailing numbers removed
    def root_name
      mailbox =~ /\A(.+?)\d+\z/ ? $1 : mailbox
    end

    ############################################################################
    # Validations
    ############################################################################

    # True if the part is valid according to the configurations
    def valid?(format = @config[:local_format] || :conventional)
      if @config[:mailbox_validator].is_a?(Proc)
        @config[:mailbox_validator].call(mailbox, tag)
      elsif format.is_a?(Proc)
        format.call(self)
      elsif format == :conventional
        conventional?
      elsif format == :relaxed
        relaxed?
      elsif format == :redacted
        redacted?
      elsif format == :standard
        standard?
      elsif format == :none
        true
      else
        raise "Unknown format #{format}"
      end
    end

    # Returns the format of the address
    def format?
      # if :custom
      if conventional?
        :conventional
      elsif relaxed?
        :relax
      elsif redacted?
        :redacted
      elsif standard?
        :standard
      else
        :invalid
      end
    end

    def valid_size?
      return set_error(:local_size_long) if local.size > STANDARD_MAX_SIZE
      if @host&.hosted_service?
        return false if @config[:local_private_size] && !valid_size_checks(@config[:local_private_size])
      elsif @config[:local_size] && !valid_size_checks(@config[:local_size])
        return false
      end
      return false if @config[:mailbox_size] && !valid_size_checks(@config[:mailbox_size])
      true
    end

    def valid_size_checks(range)
      return set_error(:local_size_short) if mailbox.size < range.first
      return set_error(:local_size_long) if mailbox.size > range.last
      true
    end

    def valid_encoding?(enc = @config[:local_encoding] || :ascii)
      return false if enc == :ascii && unicode?
      true
    end

    # True if the part matches the conventional format
    def conventional?
      self.syntax = :invalid
      if tag
        return false unless mailbox =~ CONVENTIONAL_MAILBOX_REGEX &&
          tag =~ CONVENTIONAL_TAG_REGEX
      else
        return false unless CONVENTIONAL_MAILBOX_REGEX.match?(local)
      end
      valid_size? or return false
      valid_encoding? or return false
      self.syntax = :conventional
      true
    end

    # Relaxed conventional is not so strict about character order.
    def relaxed?
      self.syntax = :invalid
      valid_size? or return false
      valid_encoding? or return false
      if tag
        return false unless RELAXED_MAILBOX_REGEX.match?(mailbox) &&
          RELAXED_TAG_REGEX.match?(tag)
        self.syntax = :relaxed
        true
      elsif RELAXED_MAILBOX_REGEX.match?(local)
        self.syntax = :relaxed
        true
      else
        false
      end
    end

    # True if the part matches the RFC standard format
    def standard?
      self.syntax = :invalid
      valid_size? or return false
      valid_encoding? or return false
      if STANDARD_LOCAL_REGEX.match?(local)
        self.syntax = :standard
        true
      else
        false
      end
    end

    # Matches configured formated form against File glob strings given.
    # Rules must end in @ to distinguish themselves from other email part matches.
    def matches?(*rules)
      rules.flatten.each do |r|
        if r =~ /(.+)@\z/
          return r if File.fnmatch?($1, local)
        end
      end
      false
    end

    def set_error(err, reason = nil)
      @error = err
      @reason = reason
      @error_message = Config.error_message(err, locale)
      false
    end

    attr_reader :error_message

    def error
      valid? ? nil : (@error || :local_invalid)
    end
  end
end
