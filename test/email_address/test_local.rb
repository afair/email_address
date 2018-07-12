# encoding: UTF-8
require_relative '../test_helper'

class TestLocal < MiniTest::Test

  def test_valid_standard
    [ # Via https://en.wikipedia.org/wiki/Email_address
      %Q{prettyandsimple},
      %Q{very.common},
      %Q{disposable.style.email.with+symbol},
      %Q{other.email-with-dash},
      %Q{"much.more unusual"},
      %Q{"(comment)very.unusual.@.unusual.com"},
      %Q{#!$%&'*+-/=?^_`{}|~},
      %Q{" "},
      %Q{"very.(),:;<>[]\\".VERY.\\"very@\\ \\"very\\".unusual"},
      %Q{"()<>[]:,;@\\\"!#$%&'*+-/=?^_`{}| ~.a"},
      %Q{token." ".token},
      %Q{abc."defghi".xyz},
    ].each do |local|
      assert EmailAddress::Local.new(local, local_fix: false).standard?, local
    end
  end

  def test_invalid_standard
    [ # Via https://en.wikipedia.org/wiki/Email_address
      %Q{A@b@c},
      %Q{a"b(c)d,e:f;g<h>i[j\k]l},
      %Q{just"not"right},
      %Q{this is"not\allowed},
      %Q{this\ still\"not\\allowed},
      %Q{john..doe},
      %Q{ invalid},
      %Q{invalid },
      %Q{abc"defghi"xyz},
    ].each do |local|
      assert_equal false, EmailAddress::Local.new(local, local_fix: false).standard?, local
    end
  end

  def test_relaxed
    assert EmailAddress::Local.new("first..last", local_format: :relaxed).valid?, "relax.."
    assert EmailAddress::Local.new("first.-last", local_format: :relaxed).valid?, "relax.-"
    assert EmailAddress::Local.new("a", local_format: :relaxed).valid?, "relax single"
    assert ! EmailAddress::Local.new("firstlast_", local_format: :relaxed).valid?, "last_"
  end

  def test_unicode
    assert ! EmailAddress::Local.new("üñîçøðé1", local_encoding: :ascii).standard?, "not üñîçøðé1"
    assert EmailAddress::Local.new("üñîçøðé2", local_encoding: :unicode).standard?, "üñîçøðé2"
    assert EmailAddress::Local.new("test", local_encoding: :unicode).valid?, "unicode should include ascii"
    assert ! EmailAddress::Local.new("üñîçøðé3").valid?, "üñîçøðé3 valid"
  end


  def test_valid_conventional
    %w( first.last first First+Tag o'brien).each do |local|
      assert EmailAddress::Local.new(local).conventional?, local
    end
  end

  def test_invalid_conventional
    (%w( first;.last +leading trailing+ o%brien) + ["first space"]).each do |local|
      assert ! EmailAddress::Local.new(local, local_fix:false).conventional?, local
    end
  end

  def test_valid
    assert_equal false, EmailAddress::Local.new("first(comment)", local_format: :conventional).valid?
    assert_equal true, EmailAddress::Local.new("first(comment)", local_format: :standard).valid?
  end

  def test_format
    assert_equal :conventional, EmailAddress::Local.new("can1").format?
    assert_equal :standard, EmailAddress::Local.new(%Q{"can1"}).format?
    assert_equal "can1", EmailAddress::Local.new(%Q{"can1(commment)"}).format(:conventional)
  end

  def test_redacted
    l = "{bea3f3560a757f8142d38d212a931237b218eb5e}"
    assert EmailAddress::Local.redacted?(l), "redacted? #{l}"
    assert_equal :redacted, EmailAddress::Local.new(l).format?
  end

  def test_matches
    a = EmailAddress.new("User+tag@gmail.com")
    assert_equal false,  a.matches?('user')
    assert_equal false,  a.matches?('user@')
    assert_equal 'user*@',  a.matches?('user*@')
  end

  def test_munge
    assert_equal "us*****", EmailAddress::Local.new("User+tag").munge
  end

  def test_hosted
    assert EmailAddress.valid?("x@exposure.co")
    assert EmailAddress.error("xxxx+subscriber@gmail.com")
    assert EmailAddress.valid?("xxxxx+subscriber@gmail.com")
  end

end
