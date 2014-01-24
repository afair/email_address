# encoding: UTF-8
require_relative 'test_helper'

class TestEmailAddress < MiniTest::Test

  def test_new
    a = EmailAddress.new('user@example.com')
    assert_equal a.local, 'user'
    assert_equal a.host, 'example.com'
  end

end
