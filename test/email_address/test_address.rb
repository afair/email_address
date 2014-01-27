#encoding: utf-8
require_relative '../test_helper'

class TestAddress < Minitest::Test
  def test_address
    a = EmailAddress.new("User+tag@example.com")
    assert_equal "user+tag", a.local.to_s
    assert_equal "example.com", a.host.to_s
    assert_equal :unknown, a.provider
  end
  
  def test_noramlize
    a = EmailAddress.new("User+tag@Example.com")
    assert_equal "user+tag@example.com", a.normalize
  end

  def test_canonical
    a = EmailAddress.new("User+tag@Example.com")
    assert_equal "user@example.com", a.canonical
    a = EmailAddress.new("first.last+tag@gmail.com")
    assert_equal "firstlast@gmail.com", a.canonical
  end

  def test_digest
    a = EmailAddress.new("User+tag@Example.com")
    assert_equal "b58996c504c5638798eb6b511e6f49af", a.md5
    assert_equal "63a710569261a24b3766275b7000ce8d7b32e2f7", a.sha1
    assert_equal "63a710569261a24b3766275b7000ce8d7b32e2f7@example.com", a.archive
  end
end
