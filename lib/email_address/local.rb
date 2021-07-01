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
    attr_reader   :local
    attr_accessor :mailbox, :comment, :tag, :config, :original
    attr_accessor :syntax, :locale

    # RFC-2142: MAILBOX NAMES FOR COMMON SERVICES, ROLES AND FUNCTIONS
    BUSINESS_MAILBOXES = %w(info marketing sales support)
    NETWORK_MAILBOXES  = %w(abuse noc security)
    SERVICE_MAILBOXES  = %w(postmaster hostmaster usenet news webmaster www uucp ftp)
    SYSTEM_MAILBOXES   = %w(help mailer-daemon root) # Not from RFC-2142
    ROLE_MAILBOXES     = %w(staff office orders billing careers jobs) # Not from RFC-2142
    SPECIAL_MAILBOXES  = BUSINESS_MAILBOXES + NETWORK_MAILBOXES + SERVICE_MAILBOXES +
                         SYSTEM_MAILBOXES + ROLE_MAILBOXES
    STANDARD_MAX_SIZE  = 64

    # Conventional : word([.-+'_]word)*
    CONVENTIONAL_MAILBOX_REGEX  = /\A [\p{L}\p{N}_]+ (?: [\.\-\+\'_] [\p{L}\p{N}_]+ )* \z/x
    CONVENTIONAL_MAILBOX_WITHIN = /[\p{L}\p{N}_]+ (?: [\.\-\+\'_] [\p{L}\p{N}_]+ )*/x

    # Relaxed: same characters, relaxed order
    RELAXED_MAILBOX_WITHIN = /[\p{L}\p{N}_]+ (?: [\.\-\+\'_]+ [\p{L}\p{N}_]+ )*/x
    RELAXED_MAILBOX_REGEX = /\A [\p{L}\p{N}_]+ (?: [\.\-\+\'_]+ [\p{L}\p{N}_]+ )* \z/x

    # RFC5322 Token: token."token".token (dot-separated tokens)
    #   Quoted Token can also have: SPACE \" \\ ( ) , : ; < > @ [ \ ] .
    STANDARD_LOCAL_WITHIN = /
      (?: [\p{L}\p{N}\!\#\$\%\&\'\*\+\-\/\=\?\^\_\`\{\|\}\~\(\)]+
        | \" (?: \\[\" \\] | [\x20-\x21\x23-\x2F\x3A-\x40\x5B\x5D-\x60\x7B-\x7E\p{L}\p{N}] )+ \" )
      (?: \.  (?: [\p{L}\p{N}\!\#\$\%\&\'\*\+\-\/\=\?\^\_\`\{\|\}\~\(\)]+
              | \" (?: \\[\" \\] | [\x20-\x21\x23-\x2F\x3A-\x40\x5B\x5D-\x60\x7B-\x7E\p{L}\p{N}] )+ \" ) )* /x

    STANDARD_LOCAL_REGEX = /\A #{STANDARD_LOCAL_WITHIN} \z/x

    REDACTED_REGEX = /\A \{ [0-9a-f]{40} \} \z/x # {sha1}

    CONVENTIONAL_TAG_REGEX  = #  AZaz09_!'+-/=
      %r/^([\w\!\'\+\-\/\=\.]+)$/i.freeze
    RELAXED_TAG_REGEX  = #  AZaz09_!#$%&'*+-/=?^`{|}~
      %r/^([\w\.\!\#\$\%\&\'\*\+\-\/\=\?\^\`\{\|\}\~]+)$/i.freeze

    def initialize(local, config={}, host=nil, locale="en")
      @config = config.is_a?(Hash) ? Config.new(config) : config
      self.local    = local
      @host         = host
      @locale       = locale
      @error        = @error_message = nil
    end

    def local=(raw)
      self.original = raw
      raw.downcase! if @config[:local_downcase].nil? || @config[:local_downcase]
      @local = raw

      if @config[:local_parse].is_a?(Proc)
        self.mailbox, self.tag, self.comment = @config[:local_parse].call(raw)
      else
        self.mailbox, self.tag, self.comment = self.parse(raw)
      end

      self.format
    end

    def parse(raw)
      if raw =~ /\A\"(.*)\"\z/ # Quoted
        raw = $1
        raw = raw.gsub(/\\(.)/, '\1') # Unescape
      elsif @config[:local_fix] && @config[:local_format] != :standard
        raw = raw.gsub(' ','')
        raw = raw.gsub(',','.')
        #raw.gsub!(/([^\p{L}\p{N}]{2,10})/) {|s| s[0] } # Stutter punctuation typo
      end
      raw, comment = self.parse_comment(raw)
      mailbox, tag = self.parse_tag(raw)
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
      separator = @config[:tag_separator] ||= '+'
      raw.split(separator, 2)
    end

    # True if the the value contains only Latin characters (7-bit ASCII)
    def ascii?
      ! self.unicode?
    end

    # True if the the value contains non-Latin Unicde characters
    def unicode?
      self.local =~ /[^\p{InBasicLatin}]/ ? true : false
    end

    # Returns true if the value matches the Redacted format
    def redacted?
      self.local =~ REDACTED_REGEX ? true : false
    end

    # Returns true if the value matches the Redacted format
    def self.redacted?(local)
      local =~ REDACTED_REGEX ? true : false
    end

    # Is the address for a common system or business role account?
    def special?
      SPECIAL_MAILBOXES.include?(mailbox)
    end

    def to_s
      self.format
    end

    # Builds the local string according to configurations
    def format(form=@config[:local_format]||:conventional)
      if @config[:local_format].is_a?(Proc)
        @config[:local_format].call(self)
      elsif form == :conventional
        self.conventional
      elsif form == :canonical
        self.canonical
      elsif form == :relaxed
        self.relax
      elsif form == :standard
        self.standard
      end
    end

    # Returns a conventional form of the address
    def conventional
      if self.tag
        [self.mailbox, self.tag].join(@config[:tag_separator])
      else
        self.mailbox
      end
    end

    # Returns a canonical form of the address
    def canonical
      if @config[:mailbox_canonical]
        @config[:mailbox_canonical].call(self.mailbox)
      else
        self.mailbox.downcase
      end
    end

    # Relaxed format: mailbox and tag, no comment, no extended character set
    def relax
      form = self.mailbox
      form += @config[:tag_separator] + self.tag if self.tag
      form = form.gsub(/[ \"\(\),:<>@\[\]\\]/,'')
      form
    end

    # Returns a normalized version of the standard address parts.
    def standard
      form = self.mailbox
      form += @config[:tag_separator] + self.tag if self.tag
      form += "(" + self.comment + ")" if self.comment
      form = form.gsub(/([\\\"])/, '\\\1') # Escape \ and "
      if form =~ /[ \"\(\),:<>@\[\\\]]/ # Space and "(),:;<>@[\]
        form = %Q("#{form}")
      end
      form
    end

    # Sets the part to be the conventional form
    def conventional!
      self.local = self.conventional
    end

    # Sets the part to be the canonical form
    def canonical!
      self.local = self.canonical
    end

    # Dropps unusual  parts of Standard form to form a relaxed version.
    def relax!
      self.local = self.relax
    end

    # Returns the munged form of the address, like "ma*****"
    def munge
      self.to_s.sub(/\A(.{1,2}).*/) { |m| $1 + @config[:munge_string] }
    end

    # Mailbox with trailing numbers removed
    def root_name
      self.mailbox =~ /\A(.+?)\d+\z/ ? $1 : self.mailbox
    end

    ############################################################################
    # Validations
    ############################################################################

    # True if the part is valid according to the configurations
    def valid?(format=@config[:local_format]||:conventional)
      if @config[:mailbox_validator].is_a?(Proc)
        @config[:mailbox_validator].call(self.mailbox, self.tag)
      elsif format.is_a?(Proc)
        format.call(self)
      elsif format == :conventional
        self.conventional?
      elsif format == :relaxed
        self.relaxed?
      elsif format == :redacted
        self.redacted?
      elsif format == :standard
        self.standard?
      elsif format == :none
        true
      else
        raise "Unknown format #{format}"
      end
    end

    # Returns the format of the address
    def format?
      # if :custom
      if self.conventional?
        :conventional
      elsif self.relaxed?
        :relax
      elsif self.redacted?
        :redacted
      elsif self.standard?
        :standard
      else
        :invalid
      end
    end

    def valid_size?
      return set_error(:local_size_long) if self.local.size > STANDARD_MAX_SIZE
      if @host && @host.hosted_service?
        return false if @config[:local_private_size] && !valid_size_checks(@config[:local_private_size])
      else
        return false if @config[:local_size] && !valid_size_checks(@config[:local_size])
      end
      return false if @config[:mailbox_size] && !valid_size_checks(@config[:mailbox_size])
      true
    end

    def valid_size_checks(range)
      return set_error(:local_size_short) if self.mailbox.size < range.first
      return set_error(:local_size_long)  if self.mailbox.size > range.last
      true
    end

    def valid_encoding?(enc=@config[:local_encoding]||:ascii)
      return false if enc == :ascii && self.unicode?
      true
    end

    # True if the part matches the conventional format
    def conventional?
      self.syntax = :invalid
      if self.tag
        return false unless self.mailbox =~ CONVENTIONAL_MAILBOX_REGEX &&
          self.tag =~ CONVENTIONAL_TAG_REGEX
      else
        return false unless self.local =~ CONVENTIONAL_MAILBOX_REGEX
      end
      self.valid_size? or return false
      self.valid_encoding? or return false
      self.syntax = :conventional
      true
    end

    # Relaxed conventional is not so strict about character order.
    def relaxed?
      self.syntax = :invalid
      self.valid_size? or return false
      self.valid_encoding? or return false
      if self.tag
        return false unless self.mailbox =~ RELAXED_MAILBOX_REGEX &&
          self.tag =~ RELAXED_TAG_REGEX
      elsif self.local =~ RELAXED_MAILBOX_REGEX
        self.syntax = :relaxed
        true
      else
        false
      end
    end

    # True if the part matches the RFC standard format
    def standard?
      self.syntax = :invalid
      self.valid_size? or return false
      self.valid_encoding? or return false
      if self.local =~ STANDARD_LOCAL_REGEX
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
          return r if File.fnmatch?($1, self.local)
        end
      end
      false
    end

    def set_error(err, reason=nil)
      @error = err
      @reason= reason
      @error_message = Config.error_message(err, locale)
      false
    end

    def error_message
      @error_message
    end

    def error
      self.valid? ? nil : ( @error || :local_invalid)
    end

  end
end
