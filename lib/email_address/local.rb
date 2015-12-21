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
  # (comment)mailbox | mailbox(comment)
  # . can not appear at beginning or end, or appear consecutively
  # 8-bit/UTF-8: allowed but mail-system defined
  # RFC 5321 also warns that "a host that expects to receive mail SHOULD avoid
  #   defining mailboxes where the Local-part requires (or uses) the Quoted-string form".
  # Postmaster: must always be case-insensitive
  # Case: sensitive, but usually treated as equivalent
  # Local Parts: comment, mailbox tag
  # Length: up to 64 characters
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
    CONVENTIONAL_MAILBOX_REGEX = /\A[a-z0-9]+([\.\-\+\'_][a-z0-9])*\z/
    # RFC5322 Non-Quoted: [ALPHA DIGIT ! # $ % & ' * + - / = ? ^ _ ` { | } ~]+
    STANDARD_MAILBOX_REGEX = /\A[a-z0-9\.\!\#\$\%\&\'\*\+\-\/\=\?\^\_\`\{\|\}\~]+\z/
    # RFC5322 Quoted: "( \[\ " ] | [( ) < > [ ] : ; @ , .] | SPACE | STANDARD_MAILBOX_CHARACTERS)+"
    STANDARD_QUOTED_MAILBOX_REGEX =
      /\A\"(\\[\\\"]|[\(\)\<\>\[\]\:\;\@\\,\.]|[ a-z0-9\!\#\$\%\&\'\*\+\-\/\=\?\^\_\`\{\|\}\~])+\"z/

    STANDARD_MAX_SIZE = 64

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
      else
        raw.gsub!(' ','') if @config[:local_fix]
      end
      (raw, comment) = self.parse_comment(raw)
      (mailbox, tag) = self.parse_tag(raw)
      [mailbox, tag, comment]
    end

    # "(comment)mailbox" or "mailbox(comment)", only one comment
    def parse_comment(raw)
      if raw =~ /\A\((.+?)\)(.+)\z/
        [$2, $1]
      elsif raw =~ /\A(.+)\((.+?)\)\z/
        [$1, $2]
      else
        [raw, nil]
      end
    end

    def parse_tag(raw)
      separator = @config[:tag_separator] or return [raw, nil]
      raw.split(separator, 2)
    end

    def ascii?
    end

    def unicode?
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

    # local_downcase, local_encoding, local_parse, local_validation
    # local_size local_mailbox local_tag tag_separator mailbox_canonical, mailbox_size
    def valid?

    end

    def format?
      # if :custom
      if self.conventional?
        :conventional
      elsif self.relaxed?
        :relax
      elsif self.standard?
        :standard
      else
        :invalid
      end
    end

    def valid_size?
      if @config[:local_size]
        @config[:local_size] > self.local.size
      elsif self.local.size <= STANDARD_MAX_SIZE
        true
      else
        false
      end
    end

    def valid_encoding?
      self.unicode? && @config[:local_encoding] == :ascii
    end

    def conventional?
      self.syntax = :invalid
      self.local =~ CONVENTIONAL_MAILBOX_REGEX or return false
      self.valid_size? or return false
      self.valid_encoding? or return false
      self.syntax = :conventional
      true
    end

    # Relaxed conventional is Standard, without Quoted form and allows ".."
    def relaxed?
      self.syntax = :invalid
      self.valid_encoding? or return false
      if self.local =~ STANDARD_MAILBOX_REGEX && self.valid_size?
        self.syntax = :standard
        true
      else
        false
      end
    end

    def standard?
      self.syntax = :invalid
      self.valid_size? or return false
      self.valid_encoding? or return false
      if self.relaxed_standard?
        if self.local.include?("..") # Not allowed
          self.syntax = :invalid
          false
        else
          true
        end
      elsif self.local =~ STANDARD_QUOTED_MAILBOX_REGEX
        self.syntax = :standard_quoted
        true
      else
        false
      end
    end
  end
end
