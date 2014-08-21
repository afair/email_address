# encoding: UTF-8
require_relative '../test_helper'

class TestLocal < MiniTest::Test
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

  def test_format
    a = EmailAddress::Local.new("(Comment!)First Last+tag")
    assert_equal 'firstlast+tag', a.normalize
  end

  def test_gmail
    a = EmailAddress::Local.new("first.last", EmailAddress::Host.new('gmail.com'))
    assert_equal "firstlast", a.canonical
  end
  
end
