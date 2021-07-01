require_relative "../test_helper"

class TestExchanger < MiniTest::Test
  def test_exchanger
    e = EmailAddress::Exchanger.new("gmail.com")
    assert_equal true, e.mxers.size > 1
    assert_equal :google, e.provider
    assert_equal "google.com", e.domains.first
    assert_equal "google.com", e.matches?("google.com")
    assert_equal false, e.matches?("fa00:1450:4013:c01::1a/16")
    assert_equal false, e.matches?("127.0.0.1/24")
    assert_equal true, e.mx_ips.size > 1
  end

  def test_not_found
    e = EmailAddress::Exchanger.new("oops.gmail.com")
    assert_equal 0, e.mxers.size
  end

  # assert_equal true, a.has_dns_a_record? # example.com has no MX'ers
  # def test_dns
  #  good = EmailAddress::Exchanger.new("gmail.com")
  #  bad  = EmailAddress::Exchanger.new("exampldkeie4iufe.com")
  #  assert_equal true, good.has_dns_a_record?
  #  assert_equal false, bad.has_dns_a_record?
  #  assert_equal "gmail.com", good.dns_a_record.first
  #  assert(/google.com\z/, good.mxers.first.first)
  #  #assert_equal 'google.com', good.domains.first
  # end
end
