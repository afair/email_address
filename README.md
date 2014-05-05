# Email Address

[![Gem Version](https://badge.fury.io/rb/email_address.svg)](http://rubygems.org/gems/email_address)

The EmailAddress gem is an _opinionated_ email address handler and
validator. It does not use RFC standards because they make things worse.
Email addresses should conform to a few practices that are not
RFC-Compliant.

Specifically, local parts (left side of the @):

* Should not be case sensitive.
* Should not contain spaces or anything that would cause quoting.
* Should not allow Unicode. Addressable items like this need to be
entered from any keyboard, such as the US ASCII character set. (Domain
names too, but that can be handled with Punycode.)
* Should not have comments. Neither should domains.
* Should not allow unusual symbols (not usually in names and standard
punctuation).
* Should not be verified by SMTP connections if possible.
* Should have spaces stripped automatically if enabled
* Should be of a reasonable length to identify the recipient.
* Should be human readable and writable.
* Should continue allowing for tagging.
* Should provide mechanism for handling bounce backs and VERP.
* Should be easily normalized and corrected.
* Should be canonicalized to identify duplicates if necessary.
* Should be able to be stored as a digest for privacy proctections.

If you're on board, let's go!

I intend to make this support most features I consider bad practices,
but want the "golden path" to git this model.

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
    email.obscure       #=> "63a710569261a24b3766275b7000ce8d7b32e2f7@example.com"

Email Service Provider (ESP) specific edits can be created to provide
validations and canonical manipulations. A few are given out of the box.
Providers can be defined bu email domain match rules, or by match rules
for the MX host names using domains or CIDR addresses.

    email = EmailAddress.new("First.Last+Tag@Gmail.Com")
    email.provider      #=> :gmail
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

Email addresses should be able to be "archived" or stored in a digest
format. This allows you to safely keep a record of the address and still
protect the account's privacy after it has been closed. Given an address
for inquiry, it can still look up a closed account.

    email.md5     #=> "dea073fb289e438a6d69c5384113454c"
    email.archive #=> "554d32017ab3a7fcf51c88ffce078689003bc521@gmail.com"


## Email Address Parts

The Local and Domain Parsing routines divvy the email address into these
parts from `(comment)mailbox+tag@subdomain.domain.tld`

* Local - Everything to the left of the "@"
* Mailbox - The controlling mailbox name
* Tag - Anything after the mailbox and tag separator character (usually "+")
* Comment - To be removed from the normalized form
* Host Name - Everything to the right of the "@"
* Subdomains - of the host name, if any.
* Domain Name - host name without subdomains, with TLD
* TLD - the rightmost word or set of 2-character domains ("co.uk")
* Registration Name - host name without subdomain or TLD

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
