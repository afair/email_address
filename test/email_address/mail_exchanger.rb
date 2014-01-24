#encoding: utf-8
require_relative '../test_helper'

class TestExchanger < MiniTest::Test
  def test_exchanger
    a = EmailAddress::Exchanger.new("example.com")
    #assert_equal true, a.found?
  end

  def test_dns
    good = EmailAddress::Exchanger.new("example.com")
    bad  = EmailAddress::Exchanger.new("exampldkeie4iufe.com")
    assert_equal true, good.has_dns_a_record?
    assert_equal false, bad.has_dns_a_record?

  end
end
