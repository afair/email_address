require_relative '../test_helper'

class TestDomainMatcher < MiniTest::Test
  def test_hostname
    assert_equal true, EmailAddress::DomainMatcher.matches?("example.com", "example.com")
    assert_equal true, EmailAddress::DomainMatcher.matches?("example.com", "example")
    assert_equal true, EmailAddress::DomainMatcher.matches?("example.com", ".com")
    assert_equal true, EmailAddress::DomainMatcher.matches?("example.com", ".example.com")
  end

  def test_list
    assert_equal true, EmailAddress::DomainMatcher.matches?("example.com", %w(ex .tld example))
  end
  
end
