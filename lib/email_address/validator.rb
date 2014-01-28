module EmailAddress
  class Validator
    LEGIBLE_LOCAL_REGEX = /\A[a-z0-9]+([\.\-\_\'\+][a-z0-9]+)+\z/

    def self.validate(local, host, options={})
      EmailAddress::Validator.new(local, host, options).valid?
    end

    def initialize(local, host, options={})
      @local   = local
      @host    = host
      @options = options
      @rules   = EmailAddress::Config.provider(@host.provider)
      @errors  = []
    end

    def valid?
      return false unless @rules[:valid_mailbox].call(@local.to_s)
      return false unless valid_mx? || (valid_dns? && @options[:allow_dns_a])
      return false unless valid_local?
      true
    end

    # True if the DNS A record or MX records are defined
    # Why A record? Some domains are misconfigured with only the A record. 
    def valid_dns?
      @host.exchanger.has_dns_a_record?
    end

    # True if the DNS MX records have been defined. More strict than #valid?
    def valid_mx?
      @host.exchanger.mxers.size > 0
    end

    # Allows single, simple punctuation character between words
    def legible?
      @local.to_s =~ LEGIBLE_LOCAL_REGEX
    end

    def valid_local?
      return false unless valid_local_part?(@local.mailbox)
      return false unless @local.comment.empty? || valid_local_part?(@local.comment)
      @local.tag.split(@rules[:tag_separator]).each do |t|
        return false unless valid_local_part?(t)
      end
      true
    end

    # Valid within a mailbox, tag, comment
    def valid_local_part?(p)
      p =~ LEGIBLE_LOCAL_REGEX
    end

    DOT_ATOM_REGEX = /[\w\!\#\$\%\&\'\*\+\-\/\=\?\^\`\{\|\}\~]/ 

    ############################################################################
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
    
  end
end
