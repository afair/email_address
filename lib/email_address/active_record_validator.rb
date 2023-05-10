# frozen_string_literal: true

module EmailAddress
  # ActiveRecord validator class for validating an email
  # address with this library.
  # Note the initialization happens once per process.
  #
  # Usage:
  #    validates_with EmailAddress::ActiveRecordValidator, field: :name
  #
  # Options:
  # * field: email,
  # * fields: [:email1, :email2]
  #
  # * code: custom error code (default: :invalid_address)
  # * message: custom error message (default: "Invalid Email Address")
  #
  # Default field: :email or :email_address (first found)
  #
  #
  class ActiveRecordValidator < ActiveModel::Validator
    def initialize(options = {})
      @opt = options
    end

    def validate(r)
      if @opt[:fields]
        @opt[:fields].each { |f| validate_email(r, f) }
      elsif @opt[:field]
        validate_email(r, @opt[:field])
      elsif r.respond_to? :email
        validate_email(r, :email)
      elsif r.respond_to? :email_address
        validate_email(r, :email_address)
      end
    end

    def validate_email(r, f)
      return if r[f].nil?
      e = Address.new(r[f])
      unless e.valid?
        error_code = @opt[:code] || :invalid_address
        error_message = @opt[:message] ||
          Config.error_message(:invalid_address, I18n.locale.to_s) ||
          "Invalid Email Address"
        r.errors.add(f, error_code, message: error_message)
      end
    end
  end
end
