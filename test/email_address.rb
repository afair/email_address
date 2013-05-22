# encoding: UTF-8
require_relative 'test_helper'

class TestEmailAddress < MiniTest::Unit::TestCase
  def test_address
    a = EmailAddress.new('user@example.com')
    assert_equal a.local, 'user'
    assert_equal a.tag, ''
    assert_equal a.comment, ''
    assert_equal a.domain, 'example.com'
    assert_equal a.subdomains, ''
    assert_equal a.base_domain, 'example'
    assert_equal a.dns_hostname, 'example.com'
    assert_equal a.top_level_domain, 'com'
    assert_equal a.to_s, 'user@example.com'
  end

  def test_foreign_address
    a = EmailAddress.new("user@sub.example.co.jp")
    assert_equal a.domain, "sub.example.co.jp"
    assert_equal a.subdomains, "sub"
    assert_equal a.domain_name, "example.co.jp"
    assert_equal a.base_domain, "example"
    assert_equal a.top_level_domain, "co.jp"
  end

  def test_address_tag
    a = EmailAddress.new('user+etc@example.com')
    assert_equal a.account, 'user'
    assert_equal a.tag, 'etc'
    assert_equal a.unique_address, 'user@example.com'
  end

  def test_address_comment
    a = EmailAddress.new('(comment)user@example.com')
    assert_equal a.comment, 'comment'
    assert_equal a.account, 'user'
    assert_equal a.unique_address, 'user@example.com'
  end

  def test_user_validation
    a = EmailAddress.new("user@example.co.jp")
    assert a.valid? == true
  end

  def test_unicode_domain
    a = EmailAddress.new("User@København.eu")
    assert_equal a.dns_hostname, 'xn--kbenhavn-54a.eu'
    assert_equal a.unique_address, 'user@xn--kbenhavn-54a.eu'
  end

end
