# encoding: UTF-8
require_relative '../test_helper'

class TestLocal < MiniTest::Unit::TestCase
  def test_local
    a = EmailAddress::Local.new("TestMonkey")
    assert_equal "testmonkey", a.to_s
  end

  def test_tag_comment
    a = EmailAddress::Local.new("User+tag(comment!)")
    assert_equal "user", a.mailbox
    assert_equal "comment!", a.comment
    assert_equal "tag", a.tag
  end
  
end
