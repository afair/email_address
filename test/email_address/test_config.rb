require_relative '../test_helper'

class TestConfig < MiniTest::Test
  def test_provider
    EmailAddress::Config.setup do
      add_provider :google, domain_names: %w(gmail.com googlemail.com google.com)
    end
    assert_equal true, EmailAddress::Config.setup.providers.has_key?(:google)
  end
  
end
