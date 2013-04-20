require_relative 'test_helper'

class TestEmailAddress < MiniTest::Unit::TestCase
  def test_address
    a = EmailAddress::Address.new("user@example.com")
    assert_equal a.host.host, "example.com"
    assert_equal a.host.domain_name, "example.com"
    assert_equal a.host.tld, "com"
    assert_equal a.host.subdomains, ""
  end

  def test_foreign_address
    a = EmailAddress::Address.new("user@yahoo.co.jp")
    assert_equal a.host.host, "yahoo.co.jp"
    assert_equal a.host.domain_name, "yahoo.co.jp"
    assert_equal a.host.base_domain, "yahoo"
    assert_equal a.host.tld, "co.jp"
    assert_equal a.host.subdomains, ""
  end

end
