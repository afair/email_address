module EmailAddress
  class Validator
    LEGIBLE_LOCAL_REGEX = /\A[a-z0-9]+(([\.\-\_\'\+][a-z0-9]+)+)?\z/
    DOT_ATOM_REGEX = /[\w\!\#\$\%\&\'\*\+\-\/\=\?\^\`\{\|\}\~]/

    def self.validate(address, options={})
      EmailAddress::Validator.new(address, options).valid?
    end

    def initialize(address, options={})
      @address = address
      @local   = address.local
      @host    = address.host
      @options = options
      @rules   = EmailAddress::Config.provider(@host.provider)
      @errors  = []
    end

    def valid?
      return false unless valid_sizes?
      if @rules[:valid_mailbox] && ! @rules[:valid_mailbox].call(@local.to_s)
        #p ["VALIDATOR", @local.to_s, @rules[:valid_mailbox]]
        return invalid(:mailbox_validator)
      else
        return false unless valid_local?
      end
      return invalid(:mx) unless valid_mx? || (valid_dns? && @options[:allow_dns_a])
      true
    end

    def mailbox_validator(v)
      return true unless v
      if v.is_a?(Proc)
        return invalid(:mailbox_proc) unless @rules[:valid_mailbox].call(@local)
      elsif v == :legible
        return legible?
      elsif v == :rfc
        return rfc_compliant?
      end
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

    # Allows single, simple punctua3Nz=Xj/7c9 tion character between words
    def legible?
      @local.to_s =~ LEGIBLE_LOCAL_REGEX
    end

    def valid_sizes?
      return invalid(:address_size) unless @rules[:address_size].include?(@address.to_s.size)
      return invalid(:domain_size ) unless @rules[:domain_size ].include?(@host.to_s.size)
      return invalid(:local_size  ) unless @rules[:local_size  ].include?(@local.to_s.size)
      return invalid(:mailbox_size) unless @rules[:mailbox_size].include?(@local.mailbox.size)
      true
    end

    def valid_local?
      return invalid(:mailbox) unless valid_local_part?(@local.mailbox)
      return invalid(:comment) unless @local.comment.empty? || valid_local_part?(@local.comment)
      if @local.tag
        @local.tag.split(@rules[:tag_separator]).each do |t|
          return invalid(:tag, t) unless valid_local_part?(t)
        end
      end
      true
    end

    # Valid within a mailbox, tag, comment
    def valid_local_part?(p)
      p =~ LEGIBLE_LOCAL_REGEX
    end


    def invalid(reason, *info)
      @errors << reason
      #p "INVALID ----> #{reason} for #{@local.to_s}@#{@host.to_s} #{info.inspect}"
      false
    end

    def valid_google_local?
      true
    end

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
