# encoding: UTF-8
require_relative '../test_helper'


class TestHost < MiniTest::Test
  def test_host
    a = EmailAddress::Host.new("example.com")
    assert_equal "example.com", a.host_name
    assert_equal "example.com", a.domain_name
    assert_equal "example", a.registration_name
    assert_equal "com", a.tld
    assert_equal "ex*****", a.munge
    assert_nil   a.subdomains
  end

  def test_dns_enabled
    a = EmailAddress::Host.new("example.com")
    assert_instance_of TrueClass, a.dns_enabled?
    old_setting = EmailAddress::Config.setting(:dns_lookup)
    EmailAddress::Config.configure(dns_lookup: :off)
    assert_instance_of FalseClass, a.dns_enabled?
    EmailAddress::Config.configure(dns_lookup: old_setting)
  end

  def test_foreign_host
    a = EmailAddress::Host.new("my.yahoo.co.jp")
    assert_equal "my.yahoo.co.jp", a.host_name
    assert_equal "yahoo.co.jp", a.domain_name
    assert_equal "yahoo", a.registration_name
    assert_equal "co.jp", a.tld2
    assert_equal "my", a.subdomains
  end

  def test_ip_host
    a = EmailAddress::Host.new("[127.0.0.1]")
    assert_equal "[127.0.0.1]", a.name
    assert_equal "127.0.0.1", a.ip_address
  end

  def test_unicode_host
    a = EmailAddress::Host.new("å.com")
    assert_equal "xn--5ca.com", a.dns_name
    a = EmailAddress::Host.new("xn--5ca.com", host_encoding: :unicode)
    assert_equal "å.com", a.to_s
  end

  def test_provider
    a = EmailAddress::Host.new("my.yahoo.co.jp")
    assert_equal :yahoo, a.provider
    a = EmailAddress::Host.new("example.com")
    assert_equal :default, a.provider
  end

  def test_dmarc
    d = EmailAddress::Host.new("yahoo.com").dmarc
    assert_equal 'reject', d[:p]
    d = EmailAddress::Host.new("example.com").dmarc
    assert_equal true, d.empty?
  end

  def test_ipv4
    h = EmailAddress::Host.new("[127.0.0.1]", host_allow_ip:true)
    assert_equal "127.0.0.1", h.ip_address
    assert_equal true, h.valid?
  end

  def test_ipv6
    h = EmailAddress::Host.new("[IPv6:::1]", host_allow_ip:true)
    assert_equal "::1", h.ip_address
    assert_equal true, h.valid?
  end

  def test_comment
    h = EmailAddress::Host.new("(oops)gmail.com")
    assert_equal 'gmail.com', h.to_s
    assert_equal 'oops', h.comment
    h = EmailAddress::Host.new("gmail.com(oops)")
    assert_equal 'gmail.com', h.to_s
    assert_equal 'oops', h.comment
  end

  def test_matches
    h = EmailAddress::Host.new("yahoo.co.jp")
    assert_equal false, h.matches?("gmail.com")
    assert_equal 'yahoo.co.jp', h.matches?("yahoo.co.jp")
    assert_equal '.co.jp', h.matches?(".co.jp")
    assert_equal '.jp', h.matches?(".jp")
    assert_equal 'yahoo.', h.matches?("yahoo.")
    assert_equal 'yah*.jp', h.matches?("yah*.jp")
  end

  def test_regexen
    assert "asdf.com".match EmailAddress::Host::CANONICAL_HOST_REGEX
    assert "xn--5ca.com".match EmailAddress::Host::CANONICAL_HOST_REGEX
    assert "[127.0.0.1]".match EmailAddress::Host::STANDARD_HOST_REGEX
    assert "[IPv6:2001:dead::1]".match EmailAddress::Host::STANDARD_HOST_REGEX
    assert_nil "[256.0.0.1]".match(EmailAddress::Host::STANDARD_HOST_REGEX)
  end

  def test_hosted_service
    assert EmailAddress.valid?('test@jiff.com', dns_lookup: :mx)
    assert ! EmailAddress.valid?('test@gmail.com', dns_lookup: :mx)
  end

  def test_yahoo_bad_tld
    assert ! EmailAddress.valid?('test@yahoo.badtld')
    assert ! EmailAddress.valid?('test@yahoo.wtf') # Registered, but MX IP = 0.0.0.0
  end

  def test_bad_formats
    assert ! EmailAddress::Host.new('ya  hoo.com').valid?
    assert EmailAddress::Host.new('ya  hoo.com', host_remove_spaces:true).valid?
  end

  def test_errors
    assert_equal EmailAddress::Host.new("yahoo.com").error, nil
    assert_equal EmailAddress::Host.new("example.com").error, :domain_does_not_accept_email
    assert_equal EmailAddress::Host.new("yahoo.wtf").error, :domain_unknown
    assert_equal EmailAddress::Host.new("ajsdfhajshdfklasjhd.wtf", dns_lookup: :off).error, nil
    assert_equal EmailAddress::Host.new("ya  hoo.com", dns_lookup: :off).error, :domain_invalid
    assert_equal EmailAddress::Host.new("[127.0.0.1]").error, :ip_address_forbidden
    assert_equal EmailAddress::Host.new("[127.0.0.666]", host_allow_ip:true).error, :ipv4_address_invalid
    assert_equal EmailAddress::Host.new("[IPv6::12t]", host_allow_ip:true).error, :ipv6_address_invalid
  end
end
