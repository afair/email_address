
module EmailAddress

  require "email_address/config"
  require "email_address/exchanger"
  require "email_address/host"
  require "email_address/local"
  require "email_address/address"
  require "email_address/version"
  require "email_address/active_record_validator" if defined?(ActiveModel)
  if defined?(ActiveRecord) && ::ActiveRecord::VERSION::MAJOR >= 5
    require "email_address/email_address_type"
    require "email_address/canonical_email_address_type"
  end

  # Creates an instance of this email address.
  # This is a short-cut to Email::Address::Address.new
  def self.new(email_address, config={})
    EmailAddress::Address.new(email_address, config)
  end

  # Given an email address, this returns true if the email validates, false otherwise
  def self.valid?(email_address, config={})
    self.new(email_address, config).valid?
  end

  # Given an email address, this returns nil if the email validates,
  # or a string with a small error message otherwise
  def self.error(email_address, config={})
    self.new(email_address, config).error
  end

  # Shortcut to normalize the given email address in the given format
  def self.normal(email_address, config={})
    EmailAddress::Address.new(email_address, config).to_s
  end

  # Shortcut to normalize the given email address
  def self.redact(email_address, config={})
    EmailAddress::Address.new(email_address, config).redact
  end

  # Shortcut to munge the given email address for web publishing
  # returns ma_____@do_____.com
  def self.munge(email_address, config={})
    EmailAddress::Address.new(email_address, config).munge
  end

  def self.new_redacted(email_address, config={})
    EmailAddress::Address.new(EmailAddress::Address.new(email_address, config).redact)
  end

  # Returns the Canonical form of the email address. This form is what should
  # be considered unique for an email account, lower case, and no address tags.
  def self.canonical(email_address, config={})
    EmailAddress::Address.new(email_address, config).canonical
  end

  def self.new_canonical(email_address, config={})
    EmailAddress::Address.new(EmailAddress::Address.new(email_address, config).canonical, config)
  end

  # Returns the Reference form of the email address, defined as the MD5
  # digest of the Canonical form.
  def self.reference(email_address, config={})
    EmailAddress::Address.new(email_address, config).reference
  end

  # Does the email address match any of the given rules
  def self.matches?(email_address, rules, config={})
    EmailAddress::Address.new(email_address, config).matches?(rules)
  end
end
