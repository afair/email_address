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
  # Default field: :email or :email_address (first found)
  #
  class ActiveRecordValidator < ActiveModel::Validator

    def initialize(options={})
      @opt = options
    end

    def validate(r)
      if @opt[:fields]
        @opt[:fields].each {|f| validate_email(r, f) }
      elsif @opt[:field]
        validate_email(r, @opt[:field])
      elsif r.respond_to? :email
        validate_email(r, :email)
      elsif r.respond_to? :email_address
        validate_email(r, :email_address)
      end
    end

    def validate_email(r,f)
      return if r[f].nil?
      e = EmailAddress.new(r[f])
      r.errors[f] << (@opt[:message] || "Email Address Not Valid") unless e.valid?
    end

  end

end
