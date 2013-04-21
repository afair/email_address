# EmailAddress

The EmailAddress library is an _opinionated_ email address handler and
validator. 

So you have an email address input by a user. Do you want to validate
it, check it for uniqueness, or mine statistics on all your addresses?
Then the email_address gem is for you!

Opininated? Yes. By default, this does not support RFC822 specification
because it allows addresses that should never exist for real people.
By limiting email addresses to a subset of standardly used ones, you can
remove false positives in validation, and help the email community
evolve into a friendlier place. I like standards as much as the next
person, but enough is enough!

Why my opinion? I've been working with email and such since the late
1990's. I would like to see modern practices applied to email addresses.
These rules really do apply to most (without real statistics, I'll claim
99.9+%) usage in the 21st Century. They may not be for everyone, you may
need strict adherence to these standards for historical reasons, but I
bet you'll wish you could support this one instead!

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

    email = EmailAddress.new("user@example.com")

You can see if it validates as an opinionated address:

    email.valid?

This runs the following checks you can do yourself:

    email.valid_format?
    email.valid_domain?
    email.valid_user?
    email.disposable_email?
    email.spam_trap?

Of course, the last couple tests can't be published, so you can provide
a callback to check them yourself if you need.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
