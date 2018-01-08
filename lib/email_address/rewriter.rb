require 'base64'

module EmailAddress::Rewriter

  SRS_FORMAT_REGEX   = /\ASRS0=(....)=(\w\w)=(.+?)=(.+?)@(.+)\z/

  def parse_rewritten(e)
    @rewrite_scheme = nil
    @rewrite_error  = nil
    e = parse_srs(e)
    # e = parse_batv(e)
    e
  end

  #---------------------------------------------------------------------------
  # SRS (Sender Rewriting Scheme) allows an address to be forwarded from the
  # original owner and encoded to be used with the domain name of the MTA (Mail
  # Transport Agent). It encodes the original address within the local part of the
  # sending email address and respects VERP. If example.com needs to forward a
  # message from "sender@gmail.com", the SMTP envelope sender is used at this
  # address. These methods respect DMARC and prevent spoofing email send using
  # a different domain.
  # Format: SRS0=HHH=TT=domain=local@sending-domain.com
  #---------------------------------------------------------------------------
  def srs(sending_domain, options={}, &block)
    tt = srs_tt()
    a = [tt, self.hostname, self.local.to_s].join("=") + "@" + sending_domain
    hhh = srs_hash(a, options, &block)

    ["SRS0", hhh, a].join("=")
  end

  def srs?(email)
    email.match(SRS_FORMAT_REGEX) ? true : false
  end

  def parse_srs(email, options={}, &block)
    if email && email.match(SRS_FORMAT_REGEX)
      @rewrite_scheme = :srs
      hhh, tt, domain, local, sending_domain = [$1, $2, $3, $4, $5]
      hhh = tt = sending_domain if false && hhh # Hide warnings for now :-)
      a = [tt, domain, local].join("=") + "@" + sending_domain
      unless srs_hash(a, options, &block) === hhh
        @rewrite_error = "Invalid SRS Email Address: Possibly altered"
      end
      unless tt == srs_tt
        @rewrite_error = "Invalid SRS Email Address: Too old"
      end
      [local, domain].join("@")
    else
      email
    end
  end

  # SRS Timeout Token
  # Returns a 2-character code for the day. After a few days the code will roll.
  # TT has a one-day resolution in order to make the address invalid after a few days.
  # The cycle period is 3.5 years. Used to control late bounces and harvesting.
  def srs_tt(t=Time.now.utc)
    Base64.encode64((t.to_i / (60*60*24) %  210).to_s)[0,2]
  end

  def srs_hash(email, options={}, &block)
    if block_given?
      block.call(email)[0,4]
    elsif options[:secret]
      Base64.encode64(Digest::SHA1.digest(email + options[:secret].to_s))[0,4]
    else
      # Non-Secure signing. Please give a secret
      Base64.encode64(Digest::SHA1.digest(email.reverse))[0,4]
    end
  end

  # BATV - Returns the Bounce Address Tag Validation format
  # PRVS - Simple Private Signature
  # Ex:    prvs=KDDDSSSS=pat@example.com
  #        * K: Digit for Key rotation
  #        * DDD: Expiry date, since 1970, low 3 digits
  #        * SSSSSS: sha1( KDDD + orig-mailfrom + key)[0,6]
  # Source: https://tools.ietf.org/html/draft-levine-smtp-batv-01
  def batv_prvs()
    raise "Not yet implemented"
  end

  # VERP Embeds a recipient email address into the bounce address
  #   Bounce Address:  message-id@example.net
  #   Recipient Email: bob@example.org
  #   VERP :           message-id+bob=example.org@example.net
  def verp(recipient, split_char='+', verp_at='=')
    self.local.to_s +
      split_char + recipient.gsub("@",verp_at) +
      "@" + self.hostname
  end

  # NEXT: DMARC, SPF Validation

end
