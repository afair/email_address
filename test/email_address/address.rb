#encoding: utf-8
require_relative '../test_helper'

class TestAddress < MiniTest::Unit::TestCase
  def test_address
    a = EmailAddress.new("User+tag@example.com")
    assert_equal "user", a.account
    assert_equal "user+tag", a.mailbox
    assert_equal "tag", a.tags
    assert_equal "user@example.com", a.unique_address
  end
  
  def test_unicode_user
    a = EmailAddress.new("å@example.com")
    assert_equal false, a.valid_format?
  end
end
