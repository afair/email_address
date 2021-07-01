require_relative "../test_helper"

class TestRewriter < Minitest::Test
  def test_srs
    ea = "first.LAST+tag@gmail.com"
    e = EmailAddress.new(ea)
    s = e.srs("example.com")
    assert s.match(EmailAddress::Address::SRS_FORMAT_REGEX)
    assert EmailAddress.new(s).to_s == e.to_s
  end
end
