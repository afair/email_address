require_relative '../test_helper'

class EmailAddress::TestValidator < MiniTest::Test

  def test_basic
    assert_equal true, EmailAddress.new('user.name@gmail.com').valid?
    assert_equal true, EmailAddress.new('user.name+tagme@gmail.com').valid?
  end

  def test_bad_local
    assert_equal false, EmailAddress.new('user!name@gmail.com').valid?
    assert_equal false, EmailAddress.new('***@yahoo.com').valid?
    assert_equal false, EmailAddress.new('***@unknowndom41n.com').valid?
  end

end
