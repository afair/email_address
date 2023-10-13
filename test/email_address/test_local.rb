require_relative "../test_helper"

class TestLocal < MiniTest::Test
  def test_valid_standard
    [ # Via https://en.wikipedia.org/wiki/Email_address
      %(prettyandsimple),
      %(very.common),
      %(disposable.style.email.with+symbol),
      %(other.email-with-dash),
      %("much.more unusual"),
      %{"(comment)very.unusual.@.unusual.com"},
      %(#!$%&'*+-/=?^_`{}|~),
      %(" "),
      %{"very.(),:;<>[]\\".VERY.\\"very@\\ \\"very\\".unusual"},
      %{"()<>[]:,;@\\\"!#$%&'*+-/=?^_`{}| ~.a"},
      %(token." ".token),
      %(abc."defghi".xyz)
    ].each do |local|
      assert EmailAddress::Local.new(local, local_fix: false).standard?, local
    end
  end

  def test_invalid_standard
    [ # Via https://en.wikipedia.org/wiki/Email_address
      %(A@b@c),
      %{a"b(c)d,e:f;g<h>i[j\k]l},
      %(just"not"right),
      %(this is"not\allowed),
      %(this\ still\"not\\allowed),
      %(john..doe),
      %( invalid),
      %(invalid ),
      %(abc"defghi"xyz)
    ].each do |local|
      assert_equal false, EmailAddress::Local.new(local, local_fix: false).standard?, local
    end
  end

  def test_relaxed
    assert EmailAddress::Local.new("first..last", local_format: :relaxed).valid?, "relax.."
    assert EmailAddress::Local.new("first.-last", local_format: :relaxed).valid?, "relax.-"
    assert EmailAddress::Local.new("a", local_format: :relaxed).valid?, "relax single"
    assert EmailAddress::Local.new("firstlast_", local_format: :relaxed).valid?, "last_"
  end

  def test_unicode
    assert !EmailAddress::Local.new("üñîçøðé1", local_encoding: :ascii).standard?, "not üñîçøðé1"
    assert EmailAddress::Local.new("üñîçøðé2", local_encoding: :unicode).standard?, "üñîçøðé2"
    assert EmailAddress::Local.new("test", local_encoding: :unicode).valid?, "unicode should include ascii"
    assert !EmailAddress::Local.new("üñîçøðé3").valid?, "üñîçøðé3 valid"
  end

  def test_valid_conventional
    %w[first.last first First+Tag o'brien].each do |local|
      assert EmailAddress::Local.new(local).conventional?, local
    end
  end

  def test_invalid_conventional
    (%w[first;.last +leading trailing+ o%brien] + ["first space"]).each do |local|
      assert !EmailAddress::Local.new(local, local_fix: false).conventional?, local
    end
  end

  def test_valid
    assert_equal false, EmailAddress::Local.new("first(comment)", local_format: :conventional).valid?
    assert_equal true, EmailAddress::Local.new("first(comment)", local_format: :standard).valid?
  end

  def test_format
    assert_equal :conventional, EmailAddress::Local.new("can1").format?
    assert_equal :standard, EmailAddress::Local.new(%("can1")).format?
    assert_equal "can1", EmailAddress::Local.new(%{"can1(commment)"}).format(:conventional)
  end

  def test_redacted
    l = "{bea3f3560a757f8142d38d212a931237b218eb5e}"
    assert EmailAddress::Local.redacted?(l), "redacted? #{l}"
    assert_equal :redacted, EmailAddress::Local.new(l).format?
  end

  def test_matches
    a = EmailAddress.new("User+tag@gmail.com")
    assert_equal false, a.matches?("user")
    assert_equal false, a.matches?("user@")
    assert_equal "user*@", a.matches?("user*@")
  end

  def test_munge
    assert_equal "us*****", EmailAddress::Local.new("User+tag").munge
  end

  def test_hosted
    assert EmailAddress.valid?("x@exposure.co")
    assert EmailAddress.error("xx+subscriber@gmail.com")
    assert EmailAddress.valid?("xxxxx+subscriber@gmail.com")
  end

  def test_ending_underscore
    assert EmailAddress.valid?("name_@icloud.com")
    assert EmailAddress.valid?("username_@gmail.com")
    assert EmailAddress.valid?("username_____@gmail.com")
  end

  def test_tag_punctuation
    assert EmailAddress.valid?("first.last+foo.bar@gmail.com")
  end

  def test_relaxed_tag
    assert EmailAddress.valid? "foo+abc@example.com", host_validation: :syntax, local_format: :relaxed
  end

  def test_phone_mailbox
    assert EmailAddress::Local.new("+3701234", local_format: :standard).valid?
  end
end
