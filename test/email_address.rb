require_relative 'test_helper'

class TestEmailAddress < MiniTest::Unit::TestCase
  def test_address
    a = EmailAddress::Address.new("user@example.com")
    assert_equal a.host, "example.com"
    assert_equal a.domain, "example.com"
    assert_equal a.tld, "com"
    assert_equal a.subdomains, ""
  end

  def test_foreign_address
    a = EmailAddress::Address.new("user@yahoo.co.jp")
    assert_equal a.host, "yahoo.co.jp"
    assert_equal a.domain, "yahoo.co.jp"
    assert_equal a.base_domain, "yahoo"
    assert_equal a.tld, "co.jp"
    assert_equal a.subdomains, ""
  end

end
