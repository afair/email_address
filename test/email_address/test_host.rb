# encoding: UTF-8
require_relative '../test_helper'


class TestHost < MiniTest::Test
  def test_host
    a = EmailAddress::Host.new("example.com")
    assert_equal "example.com", a.host_name
    assert_equal "example.com", a.domain_name
    assert_equal "example", a.registration_name
    assert_equal "com", a.tld
    assert_equal nil, a.subdomains
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

  def test_matches
    h = EmailAddress::Host.new("yahoo.co.jp")
    assert_equal false, h.matches?("gmail.com")
    assert_equal 'yahoo.co.jp', h.matches?("yahoo.co.jp")
    assert_equal '.co.jp', h.matches?(".co.jp")
    assert_equal '.jp', h.matches?(".jp")
    assert_equal 'yahoo.', h.matches?("yahoo.")
    assert_equal 'yah*.jp', h.matches?("yah*.jp")
  end
end
