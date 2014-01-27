require_relative '../test_helper'

class TestDomainParser < MiniTest::Test
  def test_hostname
    parts = EmailAddress::DomainParser.parse("Example.com")
    assert_equal 'example.com', parts[:domain_name]
    assert_equal 'example', parts[:registration_name]
    assert_equal 'com', parts[:tld]
    assert_equal '', parts[:subdomains]
  end

  def test_sld
    parts = EmailAddress::DomainParser.parse("sub.Example.co.uk")
    assert_equal 'example.co.uk', parts[:domain_name]
    assert_equal 'co.uk', parts[:tld]
    assert_equal 'sub', parts[:subdomains]
  end

  def test_provider
    parser = EmailAddress::DomainParser.new("gmail.com")
    assert_equal :google, parser.provider
  end

  def test_yahoo
    parser = EmailAddress::DomainParser.new("yahoo.co.uk")
    assert_equal :yahoo, parser.provider
  end
  
end
