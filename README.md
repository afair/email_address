# Email Address

[![Gem Version](https://badge.fury.io/rb/email_address.svg)](http://rubygems.org/gems/email_address)

The EmailAddress gem provides a structured datatype for email addresses
and pushes for an _opinionated_ model for which RFC patterns should be
accepted as a "best practice" and which should not be supported (in the
name of sanity).

This library provides:

* Email Address Validation
* Converting between email address forms
    * **Original:** From the user or data source
    * **Normalized:** A standardized format for identification
    * **Canonical:** A format used to identify a unique user
    * **Redacted:** A format used to store an email address privately
    * **Reference:** Digest formats for sharing addresses without exposing
them.
* Matching addresses to Email/Internet Service Providers. Per-provider
rules for:
    * Validation
    * Address Tag formats
    * Canonicalization
    * Unicode Support

## Email Addresses: The Good Parts

Email Addresses are split into two parts: the `local` and `host` part,
separated by the `@` symbol, or of the generalized format:

    mailbox+tag@subdomain.domain.tld

The **Mailbox** usually identifies the user, role account, or application.
A **Tag** is any suffix for the mailbox useful for separating and filtering
incoming email. It is usually preceded by a '+' or other character. Tags are
not always available for a given ESP or MTA.

Local Parts should consist of lower-case 7-bit ASCII alphanumeric and these characters:
`-+'.,` It should start with and end with an alphanumeric character and
no more than one special character should appear together.

Host parts contain a lower-case version of any standard domain name.
International Domain Names are allowed, and can be converted to 
[Punycode](http://en.wikipedia.org/wiki/Punycode),
an encoding system of Unicode strings into the 7-bit ASCII character set.
Domain names should be configured with MX records in DNS to receive
email, though this is sometimes mis-configured and the A record can be
used as a backup.

This is the subset of the RFC Email Address specification that should be
used.

## Email Addresses: The Bad Parts

Email addresses are defined and redefined in a series of RFC standards.
Conforming to the full standards is not recommended for easily
identifying and supporting email addresses. Among these specification,
we reject are:

* Case-sensitive local parts: `First.Last@example.com`
* Spaces and Special Characters: `"():;<>@[\\]`
* Quoting and Escaping Requirements: `"first \"nickname\" last"@example.com`
* Comment Parts: `(comment)mailbox@example.com`
* IP and IPv6 addresses as hosts: `mailbox@[127.0.0.1]`
* Non-ASCII (7-bit) characters in the local part: `Pelé@example.com`
* Validation by regular expressions like:
```
    (?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*
      |  "(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]
          |  \\[\x01-\x09\x0b\x0c\x0e-\x7f])*")
    @ (?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?
      |  \[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}
           (?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:
              (?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]
              |  \\[\x01-\x09\x0b\x0c\x0e-\x7f])+)
         \])
```

## Internationalization

The industry is moving to support Unicode characters in the local part
of the email address. Currently, SMTP supports only 7-bit ASCII, but a
new `SMTPUTF8` standard is available, but not yet widely implemented.
To work properly, global Email systems must be converted to UTF-8
encoded databases and upgraded to the new email standards.

The problem with i18n email addresses is that support outside of the
given locale becomes hard to enter addresses on keyboards for another
locale. Because of this, internationalized local parts are not yet
supported by default. They are more likely to be erroneous.

Proper personal identity can still be provided using
[MIME Encoded-Words](http://en.wikipedia.org/wiki/MIME#Encoded-Word)
in Email headers.

## Email Addresses Forms

* The **original** email address is of the format given by the user.
* The **Normalized** address has:
    * Lower-case the local and domain part
    * Tags are kept as they are important for the user
    * Remove comments and any "bad parts"
    * This format is what should be used to identify the account.
* The **Canonical** form is used to uniquely identify the mailbox.
    * Domains stored as punycode for IDN
    * Address Tags removed
    * Special characters removed (dots in gmail addresses are not
significant)
    * Lower cased and "bad parts" removed
    * Useful for locating a user who forgets registering with a tag or
with a "Bad part" in the email address.
* The **Redacted** format is used to store email address fingerprints
instead of the actual addresses:
    * Format: sha1(canonical_address)@domain
    * Given an email address, the record can be found
    * Useful for treating email addresses as sensitive data and
complying with requests to remove the address from your database and
still maintain the state of the account.
* The **Reference** form allows you to publicly share an address without
revealing the actual address.
    * Can be the MD5 or SHA1 of the normalized or canonical address
    * Useful for "do not email" lists
    * Useful for cookies that do not reveal the actual account

## Treating Email Addresses as Sensitive Data

Like Social Security and Credit Card Numbers, email addresses are
becoming more important as a personal identifier on the internet.
Increasingly, we should treat email addresses as sensitive data. If your
site/database becomes compromised by hackers, these email addresses can
be stolen and used to spam your users and to try to gain access to their
accounts. You should not be storing passwords in plain text; perhaps you
don't need to store email addresses un-encoded either.

Consider this: upon registration, store the redacted email address for
the user, and of course, the salted, encrypted password.
When the user logs in, compute the redacted email address from
the user-supplied one and look up the record. Store the original address
in the session for the user, which goes away when the user logs out.

Sometimes, users demand you strike their information from the database.
Instead of deleting their account, you can "redact" their email
address, retaining the state of the account to prevent future
access. Given the original email address again, the redacted account can
be identified if necessary.

Because of these use cases, the **redact** method on the email address
instance has been provided.

## Installation

Add this line to your application's Gemfile:

    gem 'email_address'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install email_address

## Usage

Inspect your email address string by creating an instance of
EmailAddress:

    email = EmailAddress.new("USER+tag@EXAMPLE.com")
    email.normalize     #=> "user+tag@example.com"
    email.canonical     #=> "user@example.com"
    email.redact        #=> "63a710569261a24b3766275b7000ce8d7b32e2f7@example.com"
    email.sha1          #=> "63a710569261a24b3766275b7000ce8d7b32e2f7"
    email.md5           #=> "dea073fb289e438a6d69c5384113454c"

Email Service Provider (ESP) specific edits can be created to provide
validations and canonical manipulations. A few are given out of the box.
Providers can be defined bu email domain match rules, or by match rules
for the MX host names using domains or CIDR addresses.

    email = EmailAddress.new("First.Last+Tag@Gmail.Com")
    email.provider      #=> :google
    email.canonical     #=> "firstlast@gmail.com"

Storing the canonical address with the request address (don't remove
tags given by users), you can lookup email addresses without the
original formatting, case, and tag information.

You can inspect the MX (Mail Exchanger) records

    email.host.exchanger.mxers.first
      #=> {:host=>"alt3.gmail-smtp-in.l.google.com", :ip=>"173.194.70.27", :priority=>30}

You can see if it validates as an opinionated address:

    email.valid?      # Resonably valid?
    email.errors      #=> [:mx]
    email.valid_host? # Host name is defined in DNS
    email.strict?     # Strictly valid?

You can compare email addresses:

    e1 = EmailAddress.new("First.Last@Gmail.com")
    e1.to_s           #=> "first.last@gmail.com"
    e2 = EmailAddress.new("FirstLast+tag@Gmail.com")
    e3.to_s           #=> "firstlast+tag@gmail.com"
    e3 = EmailAddress.new(e2.redact)
    e3.to_s           #=> "554d32017ab3a7fcf51c88ffce078689003bc521@gmail.com"

    e1 == e2          #=> false (Matches by normalized address)
    e1.same_as?(e2)   #=> true  (Matches as canonical address)
    e1.same_as?(e3)   #=> true  (Matches as redacted address)
    e1 < e2           #=> true  (Compares using normalized address)

## Host Inspection

The `EmailAddress::Host` can be used to inspect the email domain.

```ruby
    e1 = EmailAddress.new("First.Last@Gmail.com")
    e1.host.name                   #=> "gmail.com"
    e1.host.exchanger.mxers        #=> [["alt4.gmail-smtp-in.l.google.com", "2a00:1450:400c:c01::1b", 30],...]
    e1.host.exchanger.mx_ips       #=> ["2a00:1450:400c:c01::1b", ...]
    e1.host.matches?('.com')       #=> true
    e1.host.txt                    #=> "v=spf1 redirect=_spf.google.com"
```

## Domain Matching

You can also employ domain matching rules

    email.host.matches?('gmail.com', '.us', '.msn.com', 'yahoo')

This tests the address can be matched in the given list of domain rules:

* Full host name. (subdomain.example.com)
* TLD and domain wildcards  (.us, .msg.com)
* Registration names matching without the TLD. 'yahoo' matches:
    * "www.yahoo.com" (with Subdomains)
    * "yahoo.ca"     (any TLD)
    * "yahoo.co.jp"  (2-char TLD with 2-char Second-level)
    * But _may_ also match non-Yahoo domain names (yahoo.xxx)

## Customizing

You can change configuration options and add new providers such as:

    EmailAddress::Config.setup do
      provider :github, domains:%w(github.com github.io)
      option   :check_dns, false
    end

See `lib/email_address/config.rb` for more options.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
