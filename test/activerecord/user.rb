################################################################################
# ActiveRecord Test Setup ...
require 'sqlite3'

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

ActiveRecord::Type.register(:email_address, EmailAddress::EmailAddressType)
ActiveRecord::Type.register(:canonical_email_address,
                            EmailAddress::CanonicalEmailAddressType)

if File.exist?( ENV['EMAIL_ADDRESS_TEST_DB'] || "/tmp/email_address.gem.db")
  File.unlink( ENV['EMAIL_ADDRESS_TEST_DB'] || "/tmp/email_address.gem.db")
end
ActiveRecord::Base.establish_connection(
  :adapter  => "sqlite3",
  :database => ENV['EMAIL_ADDRESS_TEST_DB'] || "/tmp/email_address.gem.db"
)

ApplicationRecord.connection.execute("create table users (
                                     email varchar, canonical_email varchar)")
################################################################################

class User < ApplicationRecord
  attribute :email, :email_address
  attribute :canonical_email, :canonical_email_address

  validates_with EmailAddress::ActiveRecordValidator,
    fields: %i(email canonical_email)

  def email=(email_address)
    self[:canonical_email] = email_address
    self[:email]           = email_address
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
