require_relative "../test_helper"

class TestConfig < MiniTest::Test
  def test_setting
    assert_equal :mx, EmailAddress::Config.setting(:dns_lookup)
    assert_equal :off, EmailAddress::Config.setting(:dns_lookup, :off)
    assert_equal :off, EmailAddress::Config.setting(:dns_lookup)
    EmailAddress::Config.setting(:dns_lookup, :mx)
  end

  def test_configure
    assert_equal :mx, EmailAddress::Config.setting(:dns_lookup)
    assert_equal true, EmailAddress::Config.setting(:local_downcase)
    EmailAddress::Config.configure(local_downcase: false, dns_lookup: :off)
    assert_equal :off, EmailAddress::Config.setting(:dns_lookup)
    assert_equal false, EmailAddress::Config.setting(:local_downcase)
    EmailAddress::Config.configure(local_downcase: true, dns_lookup: :mx)
  end

  def test_provider
    assert_nil EmailAddress::Config.provider(:github)
    EmailAddress::Config.provider(:github, host_match: %w[github.com], local_format: :standard)
    assert_equal :standard, EmailAddress::Config.provider(:github)[:local_format]
    assert_equal :github, EmailAddress::Host.new("github.com").provider
    EmailAddress::Config.providers.delete(:github)
    assert_nil EmailAddress::Config.provider(:github)
  end
end
