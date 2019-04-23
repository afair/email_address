require_relative '../test_helper'

class TestConfig < MiniTest::Test
  def test_setting
    assert_equal :mx,  CheckEmailAddress::Config.setting(:dns_lookup)
    assert_equal :off, CheckEmailAddress::Config.setting(:dns_lookup, :off)
    assert_equal :off, CheckEmailAddress::Config.setting(:dns_lookup)
    CheckEmailAddress::Config.setting(:dns_lookup, :mx)
  end

  def test_configure
    assert_equal :mx,   CheckEmailAddress::Config.setting(:dns_lookup)
    assert_equal true,  CheckEmailAddress::Config.setting(:local_downcase)
    CheckEmailAddress::Config.configure(local_downcase:false, dns_lookup: :off)
    assert_equal :off,  CheckEmailAddress::Config.setting(:dns_lookup)
    assert_equal false, CheckEmailAddress::Config.setting(:local_downcase)
    CheckEmailAddress::Config.configure(local_downcase:true, dns_lookup: :mx)
  end

  def test_provider
    assert_nil CheckEmailAddress::Config.provider(:github)
    CheckEmailAddress::Config.provider(:github, host_match: %w(github.com), local_format: :standard)
    assert_equal :standard, CheckEmailAddress::Config.provider(:github)[:local_format]
    assert_equal :github, CheckEmailAddress::Host.new("github.com").provider
    CheckEmailAddress::Config.providers.delete(:github)
    assert_nil CheckEmailAddress::Config.provider(:github)
  end
end
