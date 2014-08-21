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
  # 8-bit/UTF-8: allowed but mail-system defined
  # RFC 5321 also warns that "a host that expects to receive mail SHOULD avoid
  #   defining mailboxes where the Local-part requires (or uses) the Quoted-string form".
  # Postmaster: must always be case-insensitive
  # Case: sensitive, but usually treated as equivalent
  # Local Parts: comment, mailbox tag
  # Length: up to 64 characters
  ##############################################################################
  class Local
    attr_accessor :mailbox, :comment, :tag, :local
    ROLE_NAMES = %w(info marketing sales support abuse noc security postmaster
                    hostmaster usenet news webmaster www uucp ftp)

    def initialize(local, host=nil)
      @provider = EmailAddress::Config.provider(host ? host.provider : :default)
      parse(local)
    end

    def parse(local)
      @local = local =~ /\A"(.)"\z/ ? $1 : local
      @local.gsub!(/\\(.)/, '\1') # Unescape
      @local.downcase! unless @provider[:case_sensitive]
      @local.gsub!(' ','') unless @provider[:keep_space]

      @mailbox = @local
      @comment = @tag = nil
      parse_comment
      parse_tag
    end

    def to_s
      normalize
    end

    def normalize
      m = @mailbox
      m+= @provider[:tag_separator] + @tag if @tag && !@tag.empty?
      m+= "(#{@comment})" if @comment && !@comment.empty? && @provider[:keep_comment]
      format(m)
    end

    def normalize!
      parse(normalize)
    end

    def canonical
      m= @mailbox.downcase
      if @provider[:canonical_mailbox]
        m = @provider[:canonical_mailbox].call(m)
      end
      format(m)
    end

    def canonicalize!
      parse(canonical)
    end

    def format(m)
      m = m.gsub(/([\\\"])/, '\\\1') # Escape \ and "
      if m =~ /[ \"\(\),:'<>@\[\\\]]/ # Space and "(),:;<>@[\]
        m = %Q("#{m}")
      end
      m
    end

    def parse_comment
      if @mailbox =~ /\A\((.+?)\)(.+)\z/
        (@comment, @mailbox) = [$1, $2]
      elsif @mailbox =~ /\A(.+)\((.+?)\)\z/
        (@mailbox, @comment) = [$1, $2]
      else
        @comment = '';
        @mailbox = @local
      end
    end

    def parse_tag
      return unless @provider[:tag_separator]
      parts = @mailbox.split(@provider[:tag_separator], 2)
      (@mailbox, @tag) = *parts if parts.size > 1
    end

    # RFC2142 - Mailbox Names for Common Services, Rules, and Functions
    def role?
      ROLE_NAMES.include?(@mailbox)
    end
  end
end
