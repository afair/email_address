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
    attr_accessor :mailbox, :comment, :tag, :local, :config, :original
    attr_accessor :syntax

    # RFC-2142: MAILBOX NAMES FOR COMMON SERVICES, ROLES AND FUNCTIONS
    BUSINESS_MAILBOXES = %w(info marketing sales support)
    NETWORK_MAILBOXES  = %w(abuse noc security)
    SERVICE_MAILBOXES  = %w(postmaster hostmaster usenet news webmaster www uucp ftp)
    SYSTEM_MAILBOXES   = %w(help mailer-daemon root) # Not from RFC-2142
    ROLE_MAILBOXES     = %w(staff office orders billing careers jobs) # Not from RFC-2142
    SPECIAL_MAILBOXES  = BUSINESS_MAILBOXES + NETWORK_MAILBOXES + SERVICE_MAILBOXES +
                         SYSTEM_MAILBOXES + ROLE_MAILBOXES

    # Conventional : word([.-+'_]word)*
    CONVENTIONAL_MAILBOX_REGEX = /\A[\p{L}\p{N}]+([\.\-\+\'_][\p{L}\p{N}]+)*\z/

    # Relaxed: same characters, relaxed order
    RELAXED_MAILBOX_REGEX = /\A [\p{L}\p{N}]+ ( [\.\-\+\'_]+ [\p{L}\p{N}]+ )* \z/x

    # RFC5322 Non-Quoted: ALPHA DIGIT ! # $ % & ' * + - / = ? ^ _ ` { | } ~
    #STANDARD_MAILBOX_REGEX = /\A[\p{L}\p{N}\.\!\#\$\%\&\'\*\+\-\/\=\?\^\_\`\{\|\}\~]+\z/

    # RFC5322 Token: token."token".token (dot-separated tokens)
    #   Quoted Token can also have: SPACE \" \\ ( ) , : ; < > @ [ \ ] .
    STANDARD_TOKEN_REGEX =
      /\A
          ( [\p{L}\p{N}\!\#\$\%\&\'\*\+\-\/\=\?\^\_\`\{\|\}\~\(\)]+
            | \" ( \\[\" \\] | [\x20 \! \x23-\x5B \x5D-\x7E \p{L} \p{N}] )+ \" )
          ( \.  ( [\p{L}\p{N}\!\#\$\%\&\'\*\+\-\/\=\?\^\_\`\{\|\}\~\(\)]+
                  | \" ( \\[\" \\] | [\x20 \! \x23-\x5B \x5D-\x7E \p{L} \p{N}] )+ \" ) )*
       \z/x

    # RFC5322 Quoted: "( \[\ " ] | [( ) < > [ ] : ; @ , .] | SPACE | STANDARD_MAILBOX_CHARACTERS)+"
    #STANDARD_QUOTED_MAILBOX_REGEX =
    #  /\A \" ( \\[\" \\]
    #         | [\( \) < > \[ \] : ; @ , \.
    #            \x20 \p{L} \p{N} ! # \$ % & ' \* \+ \- \/ = \? \^ _ ` \{ \| \} ~] )+
    #      \" \z/x

    REDACTED_REGEX = /\A \{ [0-9a-f]{40} \} \z/x # {sha1}
    STANDARD_MAX_SIZE = 64

    # local config options:
    #   local_downcase, local_encoding, local_parse local_size tag_separator
    #   mailbox_canonical, mailbox_size
    def initialize(local, config={})
      self.config   = config
      self.local    = local
    end

    def local=(raw)
      self.original = raw
      raw.downcase! if @config[:local_downcase]
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
        raw.gsub!(/\\(.)/, '\1') # Unescape
      elsif @config[:local_fix]
        raw.gsub!(' ','')
        raw.gsub!(',','.')
        raw.gsub!(/([^\p{L}\p{N}]{2,10})/) {|s| s[0] } # Stutter punctuation typo
      end
      (raw, comment) = self.parse_comment(raw)
      (mailbox, tag) = self.parse_tag(raw)
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
      separator = @config[:tag_separator] or return [raw, nil]
      raw.split(separator, 2)
    end

    def ascii?
      ! self.unicode?
    end

    def unicode?
      self.local =~ /[^\p{InBasic_Latin}]/ ? true : false
    end

    def redacted?
      self.local =~ REDACTED_REGEX
    end

    def self.redacted?(local)
      local =~ REDACTED_REGEX
    end

    def special?
      SPECIAL_MAILBOXES.include?(mailbox)
    end

    def to_s
      self.format
    end

    def format(form=@config[:local_format]||:conventional)
      if @config[:local_format].is_a?(Proc)
        @config[:local_format].call(self)
      elsif form == :conventional
        self.conventional
      elsif form == :canonical
        self.canonical
      elsif form == :relax
        self.relax
      elsif form == :standard
        self.standard
      end
    end

    def conventional
      if self.tag
        [self.mailbox, self.tag].join(@config[:tag_separator])
      else
        self.mailbox
      end
    end

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
      form.gsub!(/[ \"\(\),:<>@\[\]\\]/,'')
      form
    end

    # Returns a normalized version of the standard address parts.
    def standard
      form = self.mailbox
      form += @config[:tag_separator] + self.tag if self.tag
      form += "(" + self.comment + ")" if self.comment
      form.gsub!(/([\\\"])/, '\\\1') # Escape \ and "
      if form =~ /[ \"\(\),:<>@\[\\\]]/ # Space and "(),:;<>@[\]
        form = %Q("#{form}")
      end
      form
    end

    def conventional!
      self.local = self.conventional
    end

    def canonical!
      self.local = self.canonical
    end

    # Dropps unusual  parts of Standard form to form a relaxed version.
    def relax!
      self.local = self.relax
    end

    # Mailbox with trailing numbers removed
    def root_name
      self.mailbox =~ /\A(.+?)\d+\z/ ? $1 : self.mailbox
    end

    ############################################################################
    # Validations
    ############################################################################

    def valid?(format=@config[:local_format]||:conventional)
      if format.is_a?(Proc)
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
      return false if @config[:local_size] && @config[:local_size] < self.local.size
      return false if @config[:mailbox_size] && @config[:mailbox_size] < self.mailbox.size
      return false if self.local.size > STANDARD_MAX_SIZE
      true
    end

    def valid_encoding?(enc=@config[:local_encoding]||:ascii)
      return false if enc == :ascii && self.unicode?
      return false if enc == :unicode && self.ascii?
      true
    end

    def conventional?
      self.syntax = :invalid
      self.local =~ CONVENTIONAL_MAILBOX_REGEX or return false
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
      if self.local =~ RELAXED_MAILBOX_REGEX
        self.syntax = :relaxed
        true
      else
        false
      end
    end

    def standard?
      self.syntax = :invalid
      self.valid_size? or return false
      self.valid_encoding? or return false
      #if self.local =~ STANDARD_MAILBOX_REGEX
      #  if self.local.include?("..") # Not allowed
      #    self.syntax = :invalid
      #    false
      #  else
      #    self.syntax = :standard
      #    true
      #  end
      ##elsif self.local =~ STANDARD_QUOTED_MAILBOX_REGEX
      if self.local =~ STANDARD_TOKEN_REGEX
        self.syntax = :standard
        true
      else
        false
      end
    end
  end
end
