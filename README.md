# Email Address

[![Gem Version](https://badge.fury.io/rb/email_address.svg)](http://rubygems.org/gems/email_address)
[![CI Build](https://github.com/afair/email_address/actions/workflows/ci.yml/badge.svg)](https://github.com/afair/email_address/actions/workflows/ci.yml)
[![Code Climate](https://codeclimate.com/github/afair/email_address/badges/gpa.svg)](https://codeclimate.com/github/afair/email_address)

The `email_address` ruby gem is an opinionated validation library for
email addresses. The [RFC 5322](https://www.rfc-editor.org/rfc/rfc5322#section-3.4)
address specification defines them as extensions to the email
header syntax, not as a useful method for creating email transport
systems with user accounts, mailboxes, and routing.

The library follows "real world" email address patterns for end-user addresses.

- "Conventional" format (the default) fits most user email accounts
  as created by major email service providers and software.
  Only 7-bit ASCII characters are supported in the local (left) part.
- "Relaxed" format loosely follows conventional, allowing a looser
  punctuation format.
- "Standard" format follows the RFC. This is provided for non-user
  addresses, such as uniquely-generated destinations for
  consumption between automated systems.

RFC "Standard" Addresses allow syntaxes that most developers do not want:

- Mailboxes are case-sensitive.
- Double-quoted tokens can contain spaces, "@" symbols, and unusual punctuation.
- Parenthetical comment fields can appear at the beginning or end
  of the local (left) part.
- Addresses do not have to have fully-qualified domain names
- The Host part (after the "@") can be an IP Address

Additionally, this library respects "address tags", a convention
not specified by the RFC, with which email providers and software
append an identifier or route to the mailbox, usually after a "+" symbol.

Configuration options include specialized address formats for the largest
ESP (Email service providers) to validate against their formats.

If you have false negatives with "conventional" format, try the
`local_format: :relaxed` option. To validate to the RFC only, use the
`local_format: :standard` option. When possible, confirm the address
with the user if conventional check fails but relaxed succeeds.

Remember: the only true way to validate an email address is to successfully
send email to it. SMTP checks can help, but should only be done politely
to avoid blacklisting your application. Several (unaffiliated) services
exist to do this for you.

Finally, there are conveniences to handle storage and management of
address digests for PII removal or sharing addresses without revealing them.

The gem requires ruby only, but includes a, optional Ruby on Rails helper for
those who need to use it with ActiveRecord.

Looking for a Javascript version of this library? Check out the
[email_address](https://www.npmjs.com/package/email_address) npm module.

## Quick Start

Install the gem to your project with bundler:

    bundle add email_address

or with the gem command:

To quickly validate email addresses, use the valid? and error helpers.
`valid?` returns a boolean, and `error` returns nil if valid, otherwise
a basic error message.

```ruby
EmailAddress.valid? "allen@google.com" #=> true
EmailAddress.error "allen@bad-d0main.com" #=> "Invalid Host/Domain Name"
```

`EmailAddress` deeply validates your email addresses. It checks:

- Host name format and DNS setup
- Mailbox format according to "conventional" form. This matches most used user
  email accounts, but is a subset of the RFC specification.

It does not check:

- The mail server is configured to accept connections
- The mailbox is valid and accepts email.

By default, MX records are required in DNS. MX or "mail exchanger" records
tell where to deliver email for the domain. Many domains run their
website on one provider (ISP, Heroku, etc.), and email on a different
provider (such as G Suite). Note that `example.com`, while
a valid domain name, does not have MX records.

```ruby
EmailAddress.valid? "allen@example.com" #=> false
EmailAddress.valid? "allen@example.com", host_validation: :syntax #=> true
```

Most mail servers do not yet support Unicode mailboxes, so the default here is ASCII.

```ruby
EmailAddress.error "Pelé@google.com" #=> "Invalid Recipient/Mailbox"
EmailAddress.valid? "Pelé@google.com", local_encoding: :unicode #=> true
```

## Background

The email address specification is complex and often not what you want
when working with personal email addresses in applications. This library
introduces terms to distinguish types of email addresses.

- _Normal_ - The edited form of any input email address. Typically, it
  is lower-cased and minor "fixes" can be performed, depending on the
  configurations and email address provider.

  <CKENT@DAILYPLANET.NEWS> => <ckent@dailyplanet.news>

- _Conventional_ - Most personal account addresses are in this basic
  format, one or more "words" separated by a single simple punctuation
  character. It consists of a mailbox (user name or role account) and
  an optional address "tag" assigned by the user.

  miles.o'<brien@ncc-1701-d.ufp>

- _Relaxed_ - A less strict form of Conventional, same character set,
  must begin and end with an alpha-numeric character, but order within
  is not enforced.

  <aasdf-34-.z@example.com>

- _Standard_ - The RFC-Compliant syntax of an email address. This is
  useful when working with software-generated addresses or handling
  existing email addresses, but otherwise not useful for personal
  addresses.

  madness!."()<>[]:,;@\\\"!#$%&'\*+-/=?^\_`{}| ~.a(comment )"@example.org

- _Base_ - A unique mailbox without tags. For gmail, is uses the incoming
  punctation, essential when building an MD5, SHA1, or SHA256 to match services
  like Gravatar, and email address digest interchange.

- _Canonical_ - An unique account address, lower-cased, without the
  tag, and with irrelevant characters stripped.

  <clark.kent+scoops@gmail.com> => <clarkkent@gmail.com>

- _Reference_ - The MD5 of the Base format, used to share account
  references without exposing the private email address directly.

  <Clark.Kent+scoops@gmail.com> =>
  <clark.kent@gmail.com> => 1429a1dfc797d6e93075fef011c373fb

- _Redacted_ - A form of the email address where it is replaced by
  a SHA1-based version to remove the original address from the
  database, or to store the address privately, yet still keep it
  accessible at query time by converting the queried address to
  the redacted form.

  <Clark.Kent+scoops@gmail.com> => {bea3f3560a757f8142d38d212a931237b218eb5e}@gmail.com

- _Munged_ - An obfuscated version of the email address suitable for
  publishing on the internet, where email address harvesting
  could occur.

  <Clark.Kent+scoops@gmail.com> => cl\*\*\*\*\*@gm\*\*\*\*\*

Other terms:

- _Local_ - The left-hand side of the "@", representing the user,
  mailbox, or role, and an optional "tag".

  <mailbox+tag@example.com>; Local part: mailbox+tag

- _Mailbox_ - The destination user account or role account.
- _Tag_ - A parameter added after the mailbox, usually after the
  "+" symbol, set by the user for mail filtering and sub-accounts.
  Not all mail systems support this.
- _Host_ (sometimes called _Domain_) - The right-hand side of the "@"
  indicating the domain or host name server to delivery the email.
  If missing, "localhost" is assumed, or if not a fully-qualified
  domain name, it assumed another computer on the same network, but
  this is increasingly rare.
- _Provider_ - The Email Service Provider (ESP) providing the email
  service. Each provider may have its own email address validation
  and canonicalization rules.
- _Punycode_ - A host name with Unicode characters (International
  Domain Name or IDN) needs conversion to this ASCII-encoded format
  for DNS lookup.

  "HIRO@こんにちは世界.com" => "<hiro@xn--28j2a3ar1pp75ovm7c.com>"

Wikipedia has a great article on
[Email Addresses](https://en.wikipedia.org/wiki/Email_address),
much more readable than the section within
[RFC 5322](https://tools.ietf.org/html/rfc5322#section-3.4)

## Usage

Use `EmailAddress` to do transformations and validations. You can also
instantiate an object to inspect the address.

These top-level helpers return edited email addresses and validation
check.

```ruby
address = "Clark.Kent+scoops@gmail.com"
EmailAddress.valid?(address)    #=> true
EmailAddress.normal(address)    #=> "clark.kent+scoops@gmail.com"
EmailAddress.canonical(address) #=> "clarkkent@gmail.com"
EmailAddress.reference(address) #=> "c5be3597c391169a5ad2870f9ca51901"
EmailAddress.redact(address)    #=> "{bea3f3560a757f8142d38d212a931237b218eb5e}@gmail.com"
EmailAddress.munge(address)     #=> "cl*****@gm*****"
EmailAddress.matches?(address, 'google') #=> 'google' (true)
EmailAddress.error("#bad@example.com") #=> "Invalid Mailbox"
```

Or you can create an instance of the email address to work with it.

```ruby
email = EmailAddress.new(address) #=> #<EmailAddress::Address:0x007fe6ee150540 ...>
email.normal        #=> "clark.kent+scoops@gmail.com"
email.canonical     #=> "clarkkent@gmail.com"
email.original      #=> "Clark.Kent+scoops@gmail.com"
email.valid?        #=> true
```

Here are some other methods that are available.

````ruby
email.redact        #=> "{bea3f3560a757f8142d38d212a931237b218eb5e}@gmail.com"
email.sha1          #=> "bea3f3560a757f8142d38d212a931237b218eb5e"
email.sha256        #=> "9e2a0270f2d6778e5f647fc9eaf6992705ca183c23d1ed1166586fd54e859f75"
email.md5           #=> "c5be3597c391169a5ad2870f9ca51901"
email.host_name     #=> "gmail.com"
email.provider      #=> :google
email.mailbox       #=> "clark.kent"
email.tag           #=> "scoops"

email.host.exchangers.first[:ip] #=> "2a00:1450:400b:c02::1a"
email.host.txt_hash #=> {:v=>"spf1", :redirect=>"\_spf.google.com"}

EmailAddress.normal("HIRO@こんにちは世界.com")
                    #=> "hiro@xn--28j2a3ar1pp75ovm7c.com"
EmailAddress.normal("hiro@xn--28j2a3ar1pp75ovm7c.com", host_encoding: :unicode)
                    #=> "hiro@こんにちは世界.com"

#### Rails Validator

For Rails' ActiveRecord classes, EmailAddress provides an ActiveRecordValidator.
Specify your email address attributes with `field: :user_email`, or
`fields: [:email1, :email2]`. If neither is given, it assumes to use the
`email` or `email_address` attribute.

```ruby
class User < ActiveRecord::Base
  validates_with EmailAddress::ActiveRecordValidator, field: :email
end
````

#### Rails I18n

Copy and adapt `lib/email_address/messages.yaml` into your locales and
create an after initialization callback:

```ruby
# config/initializers/email_address.rb

Rails.application.config.after_initialize do
  I18n.available_locales.each do |locale|
    translations = I18n.t(:email_address, locale: locale)

    next unless translations.is_a? Hash

    EmailAddress::Config.error_messages translations.transform_keys(&:to_s), locale.to_s
  end
end
```

#### Rails Email Address Type Attribute

Initial support is provided for Active Record 5.0 attributes API.

First, you need to register the type in
`config/initializers/email_address.rb` along with any global
configurations you want.

```ruby
ActiveRecord::Type.register(:email_address, EmailAddress::EmailAddressType)
ActiveRecord::Type.register(:canonical_email_address,
                            EmailAddress::CanonicalEmailAddressType)
```

Assume the Users table contains the columns "email" and "canonical_email".
We want to normalize the address in "email" and store the canonical/unique
version in "canonical_email". This code will set the canonical_email when
the email attribute is assigned. With the canonical_email column,
we can look up the User, even it the given email address didn't exactly
match the registered version.

```ruby
class User < ApplicationRecord
  attribute :email, :email_address
  attribute :canonical_email, :canonical_email_address

  validates_with EmailAddress::ActiveRecordValidator,
                 fields: %i(email canonical_email)

  def email=(email_address)
    self[:canonical_email] = email_address
    self[:email] = email_address
  end

  def self.find_by_email(email)
    user   = self.find_by(email: EmailAddress.normal(email))
    user ||= self.find_by(canonical_email: EmailAddress.canonical(email))
    user ||= self.find_by(canonical_email: EmailAddress.redacted(email))
    user
  end

  def redact!
    self[:canonical_email] = EmailAddress.redact(self.canonical_email)
    self[:email]           = self[:canonical_email]
  end
end
```

Here is how the User model works:

```ruby
user = User.create(email:"Pat.Smith+registrations@gmail.com")
user.email           #=> "pat.smith+registrations@gmail.com"
user.canonical_email #=> "patsmith@gmail.com"
User.find_by_email("PAT.SMITH@GMAIL.COM")
                     #=> #<User email="pat.smith+registrations@gmail.com">
```

The `find_by_email` method looks up a given email address by the
normalized form (lower case), then by the canonical form, then finally
by the redacted form.

#### Validation

The only true validation is to send a message to the email address and
have the user (or process) verify it has been received. Syntax checks
help prevent erroneous input. Even sent messages can be silently
dropped, or bounced back after acceptance. Conditions such as a
"Mailbox Full" can mean the email address is known, but abandoned.

There are different levels of validations you can perform. By default, it will
validate to the "Provider" (if known), or "Conventional" format defined as the
"default" provider. You may pass a a list of parameters to select
which syntax and network validations to perform.

#### Comparison

You can compare email addresses:

```ruby
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
```

#### Matching

Matching addresses by simple patterns:

- Top-Level-Domain: .org
- Domain Name: example.com
- Registration Name: hotmail. (matches any TLD)
- Domain Glob: \*.exampl?.com
- Provider Name: google
- Mailbox Name or Glob: user00\*@
- Address or Glob: postmaster@domain\*.com
- Provider or Registration: msn

Usage:

```ruby
e = EmailAddress.new("Clark.Kent@Gmail.com")
e.matches?("gmail.com") #=> true
e.matches?("google")    #=> true
e.matches?(".org")      #=> false
e.matches?("g*com")     #=> true
e.matches?("gmail.")    #=> true
e.matches?("*kent*@")   #=> true
```

### Configuration

You can pass an options hash on the `.new()` and helper class methods to
control how the library treats that address. These can also be
configured during initialization by provider and default (see below).

```ruby
EmailAddress.new("clark.kent@gmail.com",
                 host_validation: :syntax, host_encoding: :unicode)
```

Globally, you can change and query configuration options:

```ruby
EmailAddress::Config.setting(:host_validation, :mx)
EmailAddress::Config.setting(:host_validation) #=> :mx
```

Or set multiple settings at once:

```ruby
EmailAddress::Config.configure(local_downcase: false, host_validation: :syntax)
```

You can add special rules by domain or provider. It takes the options
above and adds the :domain_match and :exchanger_match rules.

```ruby
EmailAddress.define_provider('google',
  domain_match:      %w(gmail.com googlemail.com),
  exchanger_match:   %w(google.com), # Requires host_validation==:mx
  local_size:        5..64,
  mailbox_canonical: ->(m) {m.gsub('.','')})
```

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
configuration options.
EmailAddress::Config.setting takes a single setting name and value,
while EmailAddress::Config.configure takes a hash of multiple settings.

```ruby
# ./config/initializers/email_address.rb
EmailAddress::Config.setting( :local_format, :relaxed )
EmailAddress::Config.configure( local_format: :relaxed, ... )
EmailAddress::Config.provider(:github,
       host_match: %w(github.com), local_format: :standard)
```

#### Override Error Messaegs

You can override the default error messages as follows:

```ruby
EmailAddress::Config.error_messages({
  invalid_address:    "Invalid Email Address",
  invalid_mailbox:    "Invalid Recipient/Mailbox",
  invalid_host:       "Invalid Host/Domain Name",
  exceeds_size:       "Address too long",
  not_allowed:        "Address is not allowed",
  incomplete_domain:  "Domain name is incomplete"}, 'en')
```

Complete settings and methods are found in the config.rb file within.

## Notes

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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

#### Project

This project lives at [https://github.com/afair/email_address/](https://github.com/afair/email_address/)

#### Authors

- [Allen Fair](https://github.com/afair) ([@allenfair](https://twitter.com/allenfair)):
  I've worked with email-based applications and email addresses since 1999.
