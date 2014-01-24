# encoding: UTF-8
require_relative '../test_helper'


class TestHost < MiniTest::Unit::TestCase
  def test_host
    a = EmailAddress::Host.new("example.com")
    assert_equal "example.com", a.host_name
    assert_equal "example.com", a.domain_name
    assert_equal "example", a.registration_name
    assert_equal "com", a.tld
    assert_equal "", a.subdomains
  end

  def test_foreign_host
    a = EmailAddress::Host.new("my.yahoo.co.jp")
    assert_equal "my.yahoo.co.jp", a.host_name
    assert_equal "yahoo.co.jp", a.domain_name
    assert_equal "yahoo", a.registration_name
    assert_equal "co.jp", a.tld
    assert_equal "my", a.subdomains
  end

  def test_ip_host
    a = EmailAddress::Host.new("[127.0.0.1]")
    assert_equal "[127.0.0.1]", a.host_name
    assert_equal "127.0.0.1", a.ip_address
    
  end

  def test_unicode_host
    a = EmailAddress::Host.new("å.com")
    assert_equal "xn--5ca.com", a.dns_host_name
  end

end
