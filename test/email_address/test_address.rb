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
    assert_equal "63a710569261a24b3766275b7000ce8d7b32e2f7@example.com", a.obscure
  end

  def test_idn
    a = EmailAddress.new("User+tag@ɹᴉɐℲuǝll∀.ws")
    assert_equal "user@xn--ull-6eb78cvh231oq7gdzb.ws", a.canonical
    assert_equal "9c06226d81149f59b4df32bb426c64a0cbafcea5@xn--ull-6eb78cvh231oq7gdzb.ws", a.obscure
  end

  def test_no_domain
    e = EmailAddress.new("User+tag.gmail.ws")
    assert_equal false, e.valid?
  end
end
