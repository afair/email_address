# encoding: UTF-8
require_relative '../test_helper'

class TestAR < MiniTest::Test
  require_relative 'user.rb'

  def test_validation
    user = User.new(email:"Pat.Jones+ASDF#GMAIL.com")
    assert_equal false, user.valid?
    user = User.new(email:"Pat.Jones+ASDF@GMAIL.com")
    assert_equal true, user.valid?
  end

  def test_datatype
    user = User.new(email:"Pat.Jones+ASDF@GMAIL.com")
    assert_equal 'pat.jones+asdf@gmail.com', user.email
    assert_equal 'patjones@gmail.com', user.canonical_email
  end

end
