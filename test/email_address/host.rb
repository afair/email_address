# encoding: UTF-8
require_relative '../test_helper'


class TestHost < MiniTest::Unit::TestCase
  def test_host
    a = EmailAddress::Host.new("example.com")
    assert_equal "example.com", a.host
    assert_equal "example.com", a.domain_name
    assert_equal "example", a.base_domain
    assert_equal ".com", a.tld
    assert_equal "", a.subdomains
  end

  def test_foreign_host
    a = EmailAddress::Host.new("yahoo.co.jp")
    assert_equal "yahoo.co.jp", a.host
    assert_equal "yahoo.co.jp", a.domain_name
    assert_equal "yahoo", a.base_domain
    assert_equal "co.jp", a.tld
    assert_equal "", a.subdomains
  end

  def test_unicode_host
    a = EmailAddress::Host.new("å.com")
    assert_equal "xn--5ca.com", a.dns_hostname
  end

end
