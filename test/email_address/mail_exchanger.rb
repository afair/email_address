#encoding: utf-8
require_relative '../test_helper'

class TestMailExchanger < MiniTest::Unit::TestCase
  def test_exchanger
    a = EmailAddress::MailExchanger.new("example.com")
    # assert_equal "user@example.com", a.unique_address
  end
end
