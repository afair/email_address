# encoding: UTF-8
require_relative 'test_helper'

class TestEmailAddress < MiniTest::Test

  def test_new
    a = EmailAddress.new('user@example.com')
    assert_equal a.local.to_s, 'user'
    assert_equal a.host.to_s, 'example.com'
  end

end
