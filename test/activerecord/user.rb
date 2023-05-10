################################################################################
# ActiveRecord Test Setup ...
################################################################################

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

dbfile = ENV["EMAIL_ADDRESS_TEST_DB"] || "/tmp/email_address.gem.db"
File.unlink(dbfile) if File.exist?(dbfile)

# Connection: JRuby vs. MRI
# Disabled JRuby checks... weird CI failures. Hopefully someone can help?
if RUBY_PLATFORM == "java" # jruby
  # require "jdbc/sqlite3"
  # require "java"
  # require "activerecord-jdbcsqlite3-adapter"
  # Jdbc::SQLite3.load_driver
  # ActiveRecord::Base.establish_connection(
  #   adapter: "jdbc",
  #   driver: "org.sqlite.JDBC",
  #   url: "jdbc:sqlite:" + dbfile
  # )
else
  require "sqlite3"
  ActiveRecord::Base.establish_connection(
    adapter: "sqlite3",
    database: dbfile
  )

  # The following would be executed for both JRuby/MRI
  ApplicationRecord.connection.execute(
    "create table users ( email varchar, canonical_email varchar)"
  )

  if defined?(ActiveRecord) && ::ActiveRecord::VERSION::MAJOR >= 5
    ActiveRecord::Type.register(:email_address, EmailAddress::EmailAddressType)
    ActiveRecord::Type.register(:canonical_email_address,
      EmailAddress::CanonicalEmailAddressType)
  end
end

################################################################################
# User Model
################################################################################

class User < ApplicationRecord
  if defined?(ActiveRecord) && ::ActiveRecord::VERSION::MAJOR >= 5
    attribute :email, :email_address
    attribute :canonical_email, :canonical_email_address
    attribute :alternate_email, :email_address
  end

  validates_with EmailAddress::ActiveRecordValidator,
    fields: %i[email canonical_email]
  validates_with EmailAddress::ActiveRecordValidator,
    field: :alternate_email, code: :some_error_code, message: "Check your email"

  def email=(email_address)
    self[:canonical_email] = email_address
    self[:email] = email_address
  end

  def self.find_by_email(email)
    user = find_by(email: EmailAddress.normal(email))
    user ||= find_by(canonical_email: EmailAddress.canonical(email))
    user ||= find_by(canonical_email: EmailAddress.redacted(email))
    user
  end

  def redact!
    self[:canonical_email] = EmailAddress.redact(canonical_email)
    self[:email] = self[:canonical_email]
  end
end
