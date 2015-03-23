require_relative '../test_helper'

class TestDomainMatcher < MiniTest::Test

  def setup
    @matcher = EmailAddress::Matcher.new(
      ".org example.com domain*.com hotmail. google user*@ root@*.com")
  end

  def test_tld
    assert_equal true, @matcher.include?("pat@example.org")
  end

  def test_domain
    assert_equal true, @matcher.include?("pat@example.com")
    assert_equal false, @matcher.include?("pat@nomatch.com")
  end

  def test_registration
    assert_equal true, @matcher.include?("pat@hotmail.ca")
  end

  def test_domain_glob
    assert_equal true, @matcher.include?("pat@domain123.com")
  end

  def test_provider
    assert_equal true, @matcher.include?("pat@gmail.com")
  end

  def test_mailbox
    assert_equal true, @matcher.include?("user123@example.com")
  end

  def test_address
    assert_equal true, @matcher.include?("root@example.com")
  end

end
