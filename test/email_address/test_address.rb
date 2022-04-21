require_relative "../test_helper"

class TestAddress < Minitest::Test
  def test_address
    a = EmailAddress.new("User+tag@example.com")
    assert_equal "user+tag", a.local.to_s
    assert_equal "example.com", a.host.to_s
    assert_equal "us*****@ex*****", a.munge
    assert_equal :default, a.provider
  end

  # LOCAL
  def test_local
    a = EmailAddress.new("User+tag@example.com")
    assert_equal "user", a.mailbox
    assert_equal "user+tag", a.left
    assert_equal "tag", a.tag
  end

  # HOST
  def test_host
    a = EmailAddress.new("User+tag@example.com")
    assert_equal "example.com", a.hostname
    # assert_equal :default, a.provider
  end

  # ADDRESS
  def test_forms
    a = EmailAddress.new("User+tag@example.com")
    assert_equal "user+tag@example.com", a.to_s
    assert_equal "user@example.com", a.base
    assert_equal "user@example.com", a.canonical
    assert_equal "{63a710569261a24b3766275b7000ce8d7b32e2f7}@example.com", a.redact
    assert_equal "{b58996c504c5638798eb6b511e6f49af}@example.com", a.redact(:md5)
    assert_equal "b58996c504c5638798eb6b511e6f49af", a.reference
    assert_equal "6bdd00c53645790ad9bbcb50caa93880", EmailAddress.reference("Gmail.User+tag@gmail.com")
  end

  def test_sha1
    a = EmailAddress.new("User+tag@example.com")
    assert_equal "63a710569261a24b3766275b7000ce8d7b32e2f7", a.sha1
  end

  def test_sha1_with_secret
    a = EmailAddress.new("User+tag@example.com", sha1_secret: "test-secret")
    assert_equal "122df4ec3ce7121db6edc06a9e29eab39a7e8007", a.sha1
  end

  def test_sha256
    a = EmailAddress.new("User+tag@example.com")
    assert_equal "b4c9a289323b21a01c3e940f150eb9b8c542587f1abfd8f0e1cc1ffc5e475514", a.sha256
  end

  def test_sha256_with_secret
    a = EmailAddress.new("User+tag@example.com", sha256_secret: "test-secret")
    assert_equal "480899ff53ccd446cc123f0c5685869644af445e788f1b559054919674307a07", a.sha256
  end

  def test_google_hosted
    a = EmailAddress.new("Ex.am.ple+tag@boomer.com")
    assert_equal a.canonical, "ex.am.ple@boomer.com"
  end

  # COMPARISON & MATCHING
  def test_compare
    a = "User+tag@example.com"
    # e = EmailAddress.new("user@example.com")
    n = EmailAddress.new(a)
    c = EmailAddress.new_canonical(a)
    # r = EmailAddress.new_redacted(a)
    assert_equal true, n == "user+tag@example.com"
    assert_equal true, n > "b@example.com"
    assert_equal true, n.same_as?(c)
    assert_equal true, n.same_as?(a)
  end

  def test_matches
    a = EmailAddress.new("User+tag@gmail.com")
    assert_equal false, a.matches?("mail.com")
    assert_equal "google", a.matches?("google")
    assert_equal "user+tag@", a.matches?("user+tag@")
    assert_equal "user*@gmail*", a.matches?("user*@gmail*")
  end

  def test_empty_address
    a = EmailAddress.new("")
    assert_equal "{9a78211436f6d425ec38f5c4e02270801f3524f8}", a.redact
    assert_equal "", a.to_s
    assert_equal "", a.canonical
    assert_equal "518ed29525738cebdac49c49e60ea9d3", a.reference
  end

  # VALIDATION
  def test_valid
    assert EmailAddress.valid?("User+tag@example.com", host_validation: :a), "valid 1"
    assert !EmailAddress.valid?("User%tag@example.com", host_validation: :a), "valid 2"
    assert EmailAddress.new("ɹᴉɐℲuǝll∀@ɹᴉɐℲuǝll∀.ws", local_encoding: :uncode, host_validation: :syntax), "valid unicode"
  end

  def test_localhost
    e = EmailAddress.new("User+tag.gmail.ws") # No domain means localhost
    assert_equal "", e.hostname
    assert_equal false, e.valid? # localhost not allowed by default
    assert_equal EmailAddress.error("user1"), "Invalid Domain Name"
    assert_equal EmailAddress.error("user1", host_local: true), "This domain is not configured to accept email"
    assert_equal EmailAddress.error("user1", host_local: true, host_auto_append: false), "Invalid Domain Name"
    assert_equal EmailAddress.error("user1@localhost", host_local: true), "This domain is not configured to accept email"
    assert_equal EmailAddress.error("user1@localhost", host_local: false, host_validation: :syntax), "localhost is not allowed for your domain name"
    assert_equal EmailAddress.error("user1@localhost", host_local: false, dns_lookup: :off), "localhost is not allowed for your domain name"
    assert_nil EmailAddress.error("user2@localhost", host_local: true, dns_lookup: :off, host_validation: :syntax)
  end

  def test_regexen
    assert "First.Last+TAG@example.com".match(EmailAddress::Address::CONVENTIONAL_REGEX)
    assert "First.Last+TAG@example.com".match(EmailAddress::Address::STANDARD_REGEX)
    assert_nil "First.Last+TAGexample.com".match(EmailAddress::Address::STANDARD_REGEX)
    assert_nil "First#Last+TAGexample.com".match(EmailAddress::Address::CONVENTIONAL_REGEX)
    assert "aasdf-34-.z@example.com".match(EmailAddress::Address::RELAXED_REGEX)
  end

  def test_srs
    ea = "first.LAST+tag@gmail.com"
    e = EmailAddress.new(ea)
    s = e.srs("example.com")
    assert s.match(EmailAddress::Address::SRS_FORMAT_REGEX)
    assert EmailAddress.new(s).to_s == e.to_s
  end

  # Quick Regression tests for addresses that should have been valid (but fixed)
  def test_issues
    assert true, EmailAddress.valid?("test@jiff.com", dns_lookup: :mx) # #7
    assert true, EmailAddress.valid?("w.-asdf-_@hotmail.com") # #8
    assert true, EmailAddress.valid?("first_last@hotmail.com") # #8
  end

  def test_issue9
    assert !EmailAddress.valid?("example.user@foo.")
    assert !EmailAddress.valid?("ogog@sss.c")
    assert !EmailAddress.valid?("example.user@foo.com/")
  end

  def test_relaxed_normal
    assert !EmailAddress.new("a.c.m.e.-industries@foo.com").valid?
    assert true, EmailAddress.new("a.c.m.e.-industries@foo.com", local_format: :relaxed).valid?
  end

  def test_nil_address
    assert_nil EmailAddress.new(nil).normal, "Expected a nil input to make nil output"
  end

  def test_nonstandard_tag
    assert EmailAddress.valid?("asdfas+-@icloud.com")
  end
end
