require_relative '../test_helper'

class EmailAddress::TestValidator < MiniTest::Test

  def test_basic
    a = EmailAddress.new('user@example.com')
    assert_equal true, a.valid?
  end

end
