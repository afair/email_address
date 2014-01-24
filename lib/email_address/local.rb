module EmailAddress
  ##############################################################################
  # EmailAddress Local part consists of
  # - comments
  # - mailbox 
  # - tag
  #-----------------------------------------------------------------------------
  # Parsing id provider-dependent, but RFC allows:
  # A-Z a-z 0-9 . ! # $ % ' * + - / = ? ^ _ { | } ~
  # Quoted: space ( ) , : ; < > @ [ ]
  # Quoted-Backslash-Escaped: \ "
  # Quote local part or dot-separated sub-parts x."y".z
  # (comment)mailbox | mailbox(comment)
  # 8-bit/UTF-8: allowed but mail-system defined
  # RFC 5321 also warns that "a host that expects to receive mail SHOULD avoid defining mailboxes where the Local-part requires (or uses) the Quoted-string form".
  # Postmaster: must always be case-insensitive
  # Case: sensitive, but usually treated as equivalent
  # Local Parts: comment, account tag
  # Length: up to 64 characters
  ##############################################################################
  class Local
    attrib_reader :mailbox, :comments, :tag, :local

    def initialize(local, host=nil)
      @host = host || EmailAddress::Provider::Default
      @local = local
      @local = $1 if $local =~ /\A"(.)"\z/
      @mailbox = @comments = @tag = ''
      parse_comment
      parse_tag
    end

    def to_s
      @local
    end

    def canonical
      @mailbox =~ /\s/ ? "#{@host.canonical_local(@mailbox)}" : @mailbox
    end

    def parse_comment
      if @local =~ /\A\((.+?)\)(.+)\z/
        (@comment, @mailbox) = [$1, $2]
      elsif @local =~ /\A(.+)\((.+?)\)\z/
        (@mailbox, @comment) = [$1, $2]
      else
        @comment = '';
      end
      self
    end

    def parse_tag
      if @mailbox.split(@host.tag_separator, 1)
        (@mailbox, @comment) = [$1, $2]
      end
    end
  end
end
