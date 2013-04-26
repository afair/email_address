#encoding: utf-8
require_relative '../test_helper'
#require 'minitest/autorun'

class TestConfig < MiniTest::Unit::TestCase
  def test_config
    EmailAddress::Config.setup do
      add_provider :google, domain_names: %w(gmail.com googlemail.com google.com)
    end
    assert_equal EmailAddress::Config.get.provider_matching_rules.first[:provider], :google
  end
  
end
