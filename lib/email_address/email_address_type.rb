################################################################################
# ActiveRecord v5.0 Custom Type
# This class is not automatically loaded by the gem.
#-------------------------------------------------------------------------------
# 1) Register this type
#
#    # config/initializers.types.rb
#    require "email_address/email_address_type"
#    ActiveRecord::Type.register(:email_address, EmailAddress::Address)
#    ActiveRecord::Type.register(:canonical_email_address,
#                                EmailAddress::CanonicalEmailAddressType)
#
# 2) Define your email address columns in your model class
#
#    class User < ActiveRecord::Base
#      attribute :email, :email_address
#      attribute :unique_email, :canonical_email_address
#    end
#
# 3) Profit!
#
#    user = User.new(email:"Pat.Smith+registrations@gmail.com",
#                    unique_email:"Pat.Smith+registrations@gmail.com")
#    user.email        #=> "pat.smith+registrations@gmail.com"
#    user.unique_email #=> "patsmith@gmail.com"
################################################################################

class EmailAddress::EmailAddressType < ActiveRecord::Type::Value

  # From user input, setter
  def cast(value)
    super(EmailAddress.normal(value))
  end

  # From a database value
  def deserialize(value)
    EmailAddress.normal(value)
  end
  #
  # To a database value (string)
  def serialize(value)
    EmailAddress.normal(value)
  end
end

class CanonicalEmailAddressType < EmailAddress::EmailAddressType

  # From user input, setter
  def cast(value)
    super(EmailAddress.canonical(value))
  end

  # From a database value
  def deserialize(value)
    EmailAddress.canonical(value)
  end

  # To a database value (string)
  def serialize(value)
    EmailAddress.canonical(value)
  end
end
