require_relative "test_helper"

class TestAliasing < MiniTest::Test
  def setup
    Object.send(:const_set, :EmailAddressValidator, EmailAddress)
    Object.send(:remove_const, :EmailAddress)
  end

  def test_email_address_not_defined
    assert_nil defined?(EmailAddress)
    assert_nil defined?(EmailAddress::Address)
    assert_nil defined?(EmailAddress::Config)
    assert_nil defined?(EmailAddress::Exchanger)
    assert_nil defined?(EmailAddress::Host)
    assert_nil defined?(EmailAddress::Local)
    assert_nil defined?(EmailAddress::Rewriter)
  end

  def test_alias_defined
    assert_equal defined?(EmailAddressValidator), "constant"
    assert_equal defined?(EmailAddressValidator::Address), "constant"
    assert_equal defined?(EmailAddressValidator::Config), "constant"
    assert_equal defined?(EmailAddressValidator::Exchanger), "constant"
    assert_equal defined?(EmailAddressValidator::Host), "constant"
    assert_equal defined?(EmailAddressValidator::Local), "constant"
    assert_equal defined?(EmailAddressValidator::Rewriter), "constant"
  end

  def test_alias_class_methods
    assert_equal true, EmailAddressValidator.valid?("user@yahoo.com")
  end

  def test_alias_host_methods
    assert_equal true, EmailAddressValidator::Host.new("yahoo.com").valid?
  end

  def test_alias_address_methods
    assert_equal true, EmailAddressValidator::Address.new("user@yahoo.com").valid?
  end

  def test_alias_config_methods
    assert Hash, EmailAddressValidator::Config.new.to_h
  end

  def test_alias_local_methods
    assert_equal true, EmailAddressValidator::Local.new("user").valid?
  end

  def teardown
    Object.send(:const_set, :EmailAddress, EmailAddressValidator)
    Object.send(:remove_const, :EmailAddressValidator)
  end
end
