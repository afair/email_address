# frozen_string_literal: true

require "base64"

module EmailAddress::Rewriter
  SRS_FORMAT_REGEX = /\ASRS0=(....)=(\w\w)=(.+?)=(.+?)@(.+)\z/

  def parse_rewritten(e)
    @rewrite_scheme = nil
    @rewrite_error = nil
    parse_srs(e)
    # e = parse_batv(e)
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
  def srs(sending_domain, options = {}, &block)
    tt = srs_tt
    a = [tt, hostname, local.to_s].join("=") + "@" + sending_domain
    hhh = srs_hash(a, options, &block)

    ["SRS0", hhh, a].join("=")
  end

  def srs?(email)
    email.match(SRS_FORMAT_REGEX) ? true : false
  end

  def parse_srs(email, options = {}, &block)
    if email&.match(SRS_FORMAT_REGEX)
      @rewrite_scheme = :srs
      hhh, tt, domain, local, sending_domain = [$1, $2, $3, $4, $5]
      # hhh = tt = sending_domain if false && hhh # Hide warnings for now :-)
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
  def srs_tt(t = Time.now.utc)
    Base64.encode64((t.to_i / (60 * 60 * 24) % 210).to_s)[0, 2]
  end

  def srs_hash(email, options = {}, &block)
    key = options[:key] || @config[:key] || email.reverse
    if block
      block.call(email)[0, 4]
    else
      Base64.encode64(Digest::SHA1.digest(email + key))[0, 4]
    end
  end

  #---------------------------------------------------------------------------
  # Returns a BATV form email address with "Private Signature" (prvs).
  # Options: key: 0-9 key digit to use
  #          key_0..key_9: secret key used to sign/verify
  #          prvs_days: number of days before address "expires"
  #
  # BATV - Bounce Address Tag Validation
  # PRVS - Simple Private Signature
  # Ex:    prvs=KDDDSSSS=user@example.com
  #        * K: Digit for Key rotation
  #        * DDD: Expiry date, since 1970, low 3 digits
  #        * SSSSSS: sha1( KDDD + orig-mailfrom + key)[0,6]
  # See:   https://tools.ietf.org/html/draft-levine-smtp-batv-01
  #---------------------------------------------------------------------------
  def batv_prvs(options = {})
    k = options[:prvs_key_id] || "0"
    prvs_days = options[:prvs_days] || @config[:prvs_days] || 30
    ddd = prvs_day(prvs_days)
    ssssss = prvs_sign(k, ddd, to_s, options)
    ["prvs=", k, ddd, ssssss, "=", to_s].join("")
  end

  PRVS_REGEX = /\Aprvs=(\d)(\d{3})(\w{6})=(.+)\z/

  def parse_prvs(email, options = {})
    if email.match(PRVS_REGEX)
      @rewrite_scheme = :prvs
      k, ddd, ssssss, email = [$1, $2, $3, $4]

      unless ssssss == prvs_sign(k, ddd, email, options)
        @rewrite_error = "Invalid BATV Address: Signature unverified"
      end
      exp = ddd.to_i
      roll = 1000 - exp # rolling 1000 day window
      today = prvs_day(0)
      # I'm sure this is wrong
      if exp > today && exp < roll
        @rewrite_error = "Invalid SRS Email Address: Address expired"
      elsif exp < today && (today - exp) > 0
        @rewrite_error = "Invalid SRS Email Address: Address expired"
      end
      [local, domain].join("@")
    else
      email
    end
  end

  def prvs_day(days)
    ((Time.now.to_i + (days * 24 * 60 * 60)) / (24 * 60 * 60)).to_s[-3, 3]
  end

  def prvs_sign(k, ddd, email, options = {})
    str = [ddd, ssssss, "=", to_s].join("")
    key = options["key_#{k}".to_i] || @config["key_#{k}".to_i] || str.reverse
    Digest::SHA1.hexdigest([k, ddd, email, key].join(""))[0, 6]
  end

  #---------------------------------------------------------------------------
  # VERP Embeds a recipient email address into the bounce address
  #   Bounce Address:  message-id@example.net
  #   Recipient Email: recipient@example.org
  #   VERP :           message-id+recipient=example.org@example.net
  # To handle incoming verp, the "tag" is the recipient email address,
  # remember to convert the last '=' into a '@' to reconstruct it.
  #---------------------------------------------------------------------------
  def verp(recipient, split_char = "+")
    local.to_s +
      split_char + recipient.tr("@", "=") +
      "@" + hostname
  end

  # NEXT: DMARC, SPF Validation
end
