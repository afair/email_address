#encoding: utf-8
require_relative '../test_helper'

class TestRewriter < Minitest::Test

  def test_srs
    ea= "first.LAST+tag@gmail.com"
    e = CheckEmailAddress.new(ea)
    s = e.srs("example.com")
    assert s.match(CheckEmailAddress::Address::SRS_FORMAT_REGEX)
    assert CheckEmailAddress.new(s).to_s == e.to_s
  end

end
