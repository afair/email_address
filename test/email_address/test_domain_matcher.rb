require_relative '../test_helper'

class TestDomainMatcher < MiniTest::Test
  MATCHER = EmailAddress::DomainMatcher

  def test_hostname
    assert_equal true, MATCHER.matches?("example.com", "example.com")
    assert_equal true, MATCHER.matches?("example.com", "example")
    assert_equal true, MATCHER.matches?("example.com", ".com")
    assert_equal true, MATCHER.matches?("example.com", ".example.com")
  end

  def test_list
    assert_equal true, MATCHER.matches?("example.com", %w(ex .tld example))
  end

  def test_glob_matches
    assert_equal true, MATCHER.matches?("example.com", %w(ex*.com))
  end

end
