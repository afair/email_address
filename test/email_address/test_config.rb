require_relative '../test_helper'

class TestConfig < MiniTest::Test
  def test_setup
    EmailAddress::Config.setup do
      provider :disposable, domains:%w(mailenator)
      option   :downcase_mailboxes, true
    end
    assert_equal true, EmailAddress::Config.providers.has_key?(:disposable)
    assert_equal true, EmailAddress::Config.options[:downcase_mailboxes]
  end
  
end
