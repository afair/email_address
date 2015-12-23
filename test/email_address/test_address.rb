#encoding: utf-8
require_relative '../test_helper'

class TestAddress < Minitest::Test
  def test_address
    a = EmailAddress.new("User+tag@example.com")
    assert_equal "user+tag", a.local.to_s
    assert_equal "example.com", a.host.to_s
    assert_equal :default, a.provider
  end

  # LOCAL
  def test_local
    a = EmailAddress.new("User+tag@example.com")
    assert_equal "user", a.mailbox
    assert_equal "user+tag", a.left
    assert_equal "tag", a.tag
  end

  # HOST
  def test_host
    a = EmailAddress.new("User+tag@example.com")
    assert_equal "example.com", a.hostname
    #assert_equal :default, a.provider
  end

  # ADDRESS
  def test_forms
    a = EmailAddress.new("User+tag@example.com")
    assert_equal "user+tag@example.com", a.to_s
    assert_equal "user@example.com", a.canonical
    assert_equal "{63a710569261a24b3766275b7000ce8d7b32e2f7}@example.com", a.redact
    assert_equal "b58996c504c5638798eb6b511e6f49af", a.reference
  end

  # COMPARISON & MATCHING
  def test_compare
    a = ("User+tag@example.com")
    #e = EmailAddress.new("user@example.com")
    n = EmailAddress.new(a)
    c = EmailAddress.new_canonical(a)
    #r = EmailAddress.new_redacted(a)
    assert_equal true, n == "user+tag@example.com"
    assert_equal true, n >  "b@example.com"
    assert_equal true, n.same_as?(c)
    assert_equal true, n.same_as?(a)
  end

  # VALIDATION
  def test_valid
    assert EmailAddress.valid?("User+tag@example.com"), "valid 1"
    assert ! EmailAddress.valid?("User%tag@example.com"), "valid 2"
    assert EmailAddress.new("ɹᴉɐℲuǝll∀@ɹᴉɐℲuǝll∀.ws", local_encoding: :uncode ), "valid unicode"
  end

  def test_no_domain
    e = EmailAddress.new("User+tag.gmail.ws")
    assert_equal 'localhost', e.hostname
    assert_equal false, e.valid? # localhost not allowed by default
  end

end
