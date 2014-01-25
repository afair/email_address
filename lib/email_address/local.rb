module EmailAddress
  ##############################################################################
  # EmailAddress Local part consists of
  # - comments
  # - mailbox 
  # - tag
  #-----------------------------------------------------------------------------
  # Parsing id provider-dependent, but RFC allows:
  # Chars: A-Z a-z 0-9 . ! # $ % ' * + - / = ? ^ _ { | } ~
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
    attr_reader :mailbox, :comment, :tag, :local

    def initialize(local, provider=nil)
      @provider = provider || EmailAddress::Providers::Default
      parse(local)
    end

    def to_s
      # Quote & Escape if necessary...
      @local
    end

    def parse(local)
      @local = local =~ /\A"(.)"\z/ ? $1 : local
      @local.gsub!(/\\(.)/, '\1') # Unescape
      @local.downcase! unless @provider.case_sensitive_mailbox

      @mailbox = @local
      parse_comment
      parse_tag
    end

    def canonical
      @mailbox =~ /\s/ ? "#{@provider.canonical_mailbox(@mailbox)}" : @mailbox
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
      return unless @provider.tag_separator
      parts = @mailbox.split(@provider.tag_separator, 2)
      (@mailbox, @tag) = *parts if parts.size > 1
    end
  end
end
