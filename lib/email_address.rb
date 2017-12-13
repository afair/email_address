
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

  class << self
    %i(valid? error normal redact munge canonical reference).each do |proxy_method|
      define_method(proxy_method) do |*args, &block|
        EmailAddress::Address.new(*args).send(proxy_method, &block)
      end if EmailAddress::Address.method_defined? proxy_method
    end
  end

  # Creates an instance of this email address.
  # This is a short-cut to Email::Address::Address.new
  def self.new(email_address, config={})
    EmailAddress::Address.new(email_address, config)
  end

  def self.new_redacted(email_address, config={})
    EmailAddress::Address.new(EmailAddress::Address.new(email_address, config).redact)
  end

  def self.new_canonical(email_address, config={})
    EmailAddress::Address.new(EmailAddress::Address.new(email_address, config).canonical, config)
  end

  # Does the email address match any of the given rules
  def self.matches?(email_address, rules, config={})
    EmailAddress::Address.new(email_address, config).matches?(rules)
  end
end
