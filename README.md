# Email Address

[![Gem Version](https://badge.fury.io/rb/email_address.svg)](http://rubygems.org/gems/email_address)

This gem provides a ruby language library for working with and validating email addresses.
By default, it validates against conventionial usage,
the format preferred for user email addresses.
It can be configured to validate against RFC "Standard" formats,
common email service provider formats, and perform DNS validation.

Warning: Version 0.1.0 contains significant API and internal changes over the 0.0.3
version. If you have been using the 0.0.x series of the gem, you may
want to stick with that.

## Installation With Rails or Bundler

If you are using Rails or a project with Bundler, add this line to your application's Gemfile:

    gem 'email_address'

And then execute:

    $ bundle

## Installation Without Bundler

If you are not using Bundler, you need to install the gem yourself.

    $ gem install email_address

Require the gem inside your script.

    require 'rubygems'
    require 'email_address'

## Usage

`EmailAddress` can create a new object to work with the address,
and also has helper to do easy transformations. See the definitions of the
email address forms later in this README for a better understanding of rules
used in this library.

These top-level helpers return edited email addresses and validation
check.

    address = "Clark.Kent+scoops@gmail.com"
    EmailAddress.valid?(address)    #=> true
    EmailAddress.normal(address)    #=> "clark.kent+scoops@gmail.com"
    EmailAddress.canonical(address) #=> "clarkkent@gmail.com"
    EmailAddress.reference(address) #=> "c5be3597c391169a5ad2870f9ca51901"
    EmailAddress.redact(address)    #=> "{bea3f3560a757f8142d38d212a931237b218eb5e}@gmail.com"
    EmailAddress.matches?(address, 'google') #=> 'google' (true)

Or you can create an instance of the email address to work with it.

    email = EmailAddress.new(address) #=> #<EmailAddress::Address:0x007fe6ee150540 ...>
    email.to_s          #=> "clark.kent+scoops@gmail.com"
    email.normalize     #=> "clark.kent+scoops@gmail.com"
    email.canonical     #=> "clarkkent@gmail.com"
    email.original      #=> "Clark.Kent+scoops@gmail.com"
    email.valid?        #=> true
    email.errors        #=> []

Here are some other methods that are available.

    email.redact        #=> "{bea3f3560a757f8142d38d212a931237b218eb5e}@gmail.com"
    email.sha1          #=> "bea3f3560a757f8142d38d212a931237b218eb5e"
    email.md5           #=> "c5be3597c391169a5ad2870f9ca51901"
    email.host_name     #=> "gmail.com"
    email.provider      #=> :google
    email.mailbox       #=> "clark.kent"
    email.tag           #=> "scoops"

    email.host.exchanger.first[:ip] #=> "2a00:1450:400b:c02::1a"
    email.host.txt_hash #=> {:v=>"spf1", :redirect=>"\_spf.google.com"}

    EmailAddress.normal("HIRO@こんにちは世界.com")
                        #=> "hiro@xn--28j2a3ar1pp75ovm7c.com"
    EmailAddress.normal("hiro@xn--28j2a3ar1pp75ovm7c.com", host_encoding: :unicode)
                        #=> "hiro@こんにちは世界.com"

### Configuration

You can pass an options hash on the `.new()` and helper class methods to
control how the library treats that address. These can also be
configured during initialization by provider and default (see below).

    EmailAddress.new("clark.kent@gmail.com",
                     dns_lookup::off, host_encoding: :unicode)

Globally, you can change and query configuration options:

    EmailAddress::Config.setting(:dns_lookup, :mx)
    EmailAddress::Config.setting(:dns_lookup) #=> :mx

Or set multiple settings at once:

    EmailAddress::Config.configure(local_downcase:false, dns_lookup: :off)

You can add special rules by domain or provider. It takes the options
above and adds the :domain_match and :exchanger_match rules.

    EmailAddress.define_provider('google',
      domain_match:      %w(gmail.com googlemail.com),
      exchanger_match:   %w(google.com), # Requires dns_lookup==:mx
      local_size:        5..64,
      mailbox_canonical: ->(m) {m.gsub('.','')})

The library ships with the most common set of provider rules. It is not meant
to house a database of all providers, but a separate `email_address-providers`
gem may be created to hold this data for those who need more complete rules.

Personal and Corporate email systems are not intended for either solution.
Any of these email systems may be configured locally.

Pre-configured email address providers include: Google (gmail), AOL, MSN
(hotmail, live, outlook), and Yahoo. Any address not matching one of
those patterns use the "default" provider rule set. Exchanger matches
matches against the Mail Exchanger (SMTP receivers) hosts defined in
DNS. If you specify an exchanger pattern, but requires a DNS MX lookup.

For Rails application, create an initializer file with your default
configuration options:

    # ./config/initializers/email_address.rb
    EmailAddress::Config.setting( local_format: :relaxed )
    EmailAddress::Config.provider(:github,
           host_match: %w(github.com), local_format: :standard)

### Available Configuration Settings

* dns_lookup: Enables DNS lookup for validation by
    * :mx       - DNS MX Record lookup
    * :a        - DNS A Record lookup (as some domains don't specify an MX incorrectly)
    * :off      - Do not perform DNS lookup (Test mode, network unavailable)

For local part configuration:

* local_downcase: true.
  Downcase the local part. You probably want this for uniqueness.
  RFC says local part is case insensitive, that's a bad part.

* local_fix:  true.
  Make simple fixes when available, remove spaces, condense multiple punctuations

* local_encoding:     :ascii, :unicode,
  Enable Unicode in local part. Most mail systems do not yet support this.
  You probably want to stay with ASCII for now.

* local_parse:        nil, ->(local) { [mailbox, tag, comment] }
  Specify an optional lambda/Proc to parse the local part. It should return an
  array (tuple) of mailbox, tag, and comment.

* local_format:
    * :conventional - word ( puncuation{1} word )*
    * :relaxed      - alphanum ( allowed_characters)* alphanum
    * :standard     - RFC Compliant email addresses (anything goes!)

* local_size:         1..64,
  A Range specifying the allowed size for mailbox + tags + comment

* tag_separator:      nil, character (+)
  Nil, or a character used to split the tag from the mailbox

For the mailbox (AKA account, role), without the tag
* mailbox_size:       1..64
  A Range specifying the allowed size for mailbox

* mailbox_canonical:  nil, ->(mailbox) { mailbox }
  An optional lambda/Proc taking a mailbox name, returning a canonical
  version of it. (E.G.: gmail removes '.' characters)

* mailbox_validator:  nil, ->(mailbox) { true }
  An optional lambda/Proc taking a mailbox name, returning true or false.

* host_encoding:      :punycode,  :unicode,
  How to treat International Domain Names (IDN). Note that most mail and
  DNS systems do not support unicode, so punycode needs to be passed.
  :punycode           Convert Unicode names to punycode representation
  :unicode            Keep Unicode names as is.

* host_validation:
  :mx                 Ensure host is configured with DNS MX records
  :a                  Ensure host is known to DNS (A Record)
  :syntax             Validate by syntax only, no Network verification
  :connect            Attempt host connection (not implemented, BAD!)

* host_size:          1..253,
  A range specifying the size limit of the host part,

* host_allow_ip:      false,
  Allow IP address format in host: [127.0.0.1], [IPv6:::1]

* address_validation: :parts, :smtp, ->(address) { true }
  Address validation policy
  :parts              Validate local and host.
  :smtp               Validate via SMTP (not implemented, BAD!)
  A lambda/Proc taking the address string, returning true or false

* address_size:       3..254,
  A range specifying the size limit of the complete address

* address_local:      false,
  Allow localhost, no domain, or local subdomains.

For provider rules to match to domain names and Exchanger hosts
The value is an array of match tokens.
* host_match:         %w(.org example.com hotmail. user*@ sub.*.com)
* exchanger_match:    %w(google.com 127.0.0.1 10.9.8.0/24 ::1/64)

#### Rails Validator

For Rails' ActiveRecord classes, EmailAddress provides an ActiveRecordValidator.

    class User < ActiveRecord::Base
      validates_with EmailAddress::ActiveRecordValidator, field: :email
    end

#### Rails Email Address Type Attribute

Initial support is provided for Active Record 5.0 and above.

First, you need to register the type in `config/initializers/types.rb`

    require "email_address"
    ActiveRecord::Type.register(:email_address, EmailAddress::EmailAddressType)
    ActiveRecord::Type.register(:canonical_email_address,
                                EmailAddress::CanonicalEmailAddressType)

Assume the Users table contains the columns "email" and "unique_email". We want to normalize the address in "email" and store the canonical/unique version in "unique_email".

    class User < ActiveRecord::Base
      attribute :email, :email_address
      attribute :unique_email, :canonical_email_address
    end

Here is how the User model works:

    user = User.new(email:"Pat.Smith+registrations@gmail.com",
                    unique_email:"Pat.Smith+registrations@gmail.com")
    user.email        #=> "pat.smith+registrations@gmail.com"
    user.unique_email #=> "patsmith@gmail.com"

#### Validation

The only true validation is to send a message to the email address and
have the user (or process) verify it has been received. Syntax checks
help prevent erroneous input. Even sent messages can be silently
dropped, or bounced back after acceptance.  Conditions such as a
"Mailbox Full" can mean the email address is known, but abandoned.

There are different levels of validations you can perform. By default, it will
validate to the "Provider" (if known), or "Conventional" format defined as the
"default" provider. You may pass a a list of parameters to select
which syntax and network validations to perform.

#### Comparison

You can compare email addresses:

    e1 = EmailAddress.new("Clark.Kent@Gmail.com")
    e2 = EmailAddress.new("clark.kent+Superman@Gmail.com")
    e3 = EmailAddress.new(e2.redact)
    e1.to_s           #=> "clark.kent@gmail.com"
    e2.to_s           #=> "clark.kent+superman@gmail.com"
    e3.to_s           #=> "{bea3f3560a757f8142d38d212a931237b218eb5e}@gmail.com"

    e1 == e2          #=> false (Matches by normalized address)
    e1.same_as?(e2)   #=> true  (Matches as canonical address)
    e1.same_as?(e3)   #=> true  (Matches as redacted address)
    e1 < e2           #=> true  (Compares using normalized address)

#### Matching

Matching addresses by simple patterns:

   * Top-Level-Domain:         .org
   * Domain Name:              example.com
   * Registration Name:        hotmail.   (matches any TLD)
   * Domain Glob:              *.exampl?.com
   * Provider Name:            google
   * Mailbox Name or Glob:     user00*@
   * Address or Glob:          postmaster@domain*.com
   * Provider or Registration: msn

Usage:

    e = EmailAddress.new("Clark.Kent@Gmail.com")
    e.matches?("gmail.com") #=> true
    e.matches?("google")    #=> true
    e.matches?(".org")      #=> false
    e.matches?("g*com")     #=> true
    e.matches?("gmail.")    #=> true
    e.matches?("*kent*@")   #=> true

## Email Addresses

#### Forms and Terminology

Most of these terms were created during implemtation of this library and are
not (yet) industry standard terms.

The email address consists of the **local** part, the '@' symbol, and the
**host** name.

The local part is usually the user, mailbox, or role accont
name. Some MTA's support an optional tag, usually after a "+" or other
pre-defined symbol, which the user can specify anything to filter
or sort incomgng mail. This can also be used to create unique email
addresses that resolve to the main account.

The host name is the domain name or subdomain that resolves to an IP
Address from the DNS MX (Mail Exchanger) record. That IP should receive
email messages on port 25 over SMTP.

**Original**: email address is of the format given by the user.

**Conventional**: Email address format that conforms the the formats supported
by most email service providers. This removes the "Bad Parts" of the email address
specification. This is the format this library supports by default.

  * Lower-case the local and domain part.
  * Tags are kept as they are important for the user.
  * Remove comments and any "bad parts".
  * International Domain Names (IDN) converted to punycode.

**Relaxed**: Like conventional, but not strict about character order.
If you find you are processing a lot of eccentric email addresses, this
may be your format for the default provider.

**Standard**: Follows the RFC specifications for email addresses.
This keeps the "Bad Parts" as described later.

  * More characters available in local part, any order (except
    for consecutive "..")
  * Double-Quoted local part for an extended character set
  * Domain names are normalized (lower-case, punycode for International Domain Names (IDN).

**Relaxed**: A relaxed Standard format. Essentially Standard
form without the the Quoted extension, and a few less dangerous
characers.

**Canonical**: Used to uniquely identify the mailbox.
Useful for locating a user who forget registering with a tag or
with a "Bad part" in the email address.

  * Based on the Conventional form.
  * Address Tags removed.
  * Special characters removed (dots in gmail addresses are not
significant)

**Redacted**: This form is used to store email address fingerprints
instead of the actual addresses. Useful for treating email addresses
as sensitive data and complying with requests to remove the address
from your database and still maintain the state of the account.


  * Format: "{" + sha1(canonical_address) + "}" + @domain
  * Given an email address, the record can be found

**Reference**: These form allows you to publicly interchange an address without
revealing the actual address. While these digests are not guaranteed to be unique,
they are industry standard methods of providing matching addresses without
opening them up to harvesting. Use this in applications asking external
services "Do you know this email address?" or "Remove this email address
from your database" where providing the actual address compromises the
address if it is not known to the external service.

  * Can be the **MD5** (_default_) or **SHA1** of the normalized or canonical address
  * Useful for "do not email" lists
  * Useful for cookies that do not reveal the actual account
  * Can be used to represent an alternate recipient identifier
    in an email message to identify the email address in bounces or FBL
    messages where the actual email address is redacted or munged for privacy.

**Provider**: The name of the service providing the email either an Email Service Provider (Yahoo, Google, MSN), or ISP (Internet Service Provider) such as a
Cable TV or Telephone company.

#### The Good Parts

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

#### The Bad Parts

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

#### Internationalization

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


#### Email Addresses as Sensitive Data

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

## Customizing

See `lib/email_address/config.rb` for more options.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
