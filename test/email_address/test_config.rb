require_relative '../test_helper'

class TestConfig < MiniTest::Test
  def test_setup
    EmailAddress::Config.setup do
      provider :google, domain_names: %w(gmail.com googlemail.com google.com)
      option   :downcase_mailboxes, false
    end
    assert_equal true, EmailAddress::Config.setup.providers.has_key?(:google)
  end
  
end
