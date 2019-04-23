################################################################################
# ActiveRecord Test Setup ...
################################################################################

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

dbfile = ENV['EMAIL_ADDRESS_TEST_DB'] || "/tmp/email_address.gem.db"
File.unlink(dbfile) if File.exist?(dbfile)

# Connection: JRuby vs. MRI
if RUBY_PLATFORM == 'java' # jruby
  require 'jdbc/sqlite3'
  require 'java'
  require 'activerecord-jdbcsqlite3-adapter'
  Jdbc::SQLite3.load_driver
  ActiveRecord::Base.establish_connection(
    :adapter  => 'jdbc',
    :driver   => "org.sqlite.JDBC",
    :url      => "jdbc:sqlite:" + dbfile
  )
else
  require 'sqlite3'
  ActiveRecord::Base.establish_connection(
    :adapter  => 'sqlite3',
    :database => dbfile
  )
end

ApplicationRecord.connection.execute(
  "create table users ( email varchar, canonical_email varchar)")

if defined?(ActiveRecord) && ::ActiveRecord::VERSION::MAJOR >= 5
  ActiveRecord::Type.register(:email_address, CheckEmailAddress::CheckEmailAddressType)
  ActiveRecord::Type.register(:canonical_email_address,
                              CheckEmailAddress::CanonicalCheckEmailAddressType)
end

################################################################################
# User Model
################################################################################

class User < ApplicationRecord

  if defined?(ActiveRecord) && ::ActiveRecord::VERSION::MAJOR >= 5
    attribute :email, :email_address
    attribute :canonical_email, :canonical_email_address
  end

  validates_with CheckEmailAddress::ActiveRecordValidator,
    fields: %i(email canonical_email)

  def email=(email_address)
    self[:canonical_email] = email_address
    self[:email]           = email_address
  end

  def self.find_by_email(email)
    user   = self.find_by(email: CheckEmailAddress.normal(email))
    user ||= self.find_by(canonical_email: CheckEmailAddress.canonical(email))
    user ||= self.find_by(canonical_email: CheckEmailAddress.redacted(email))
    user
  end

  def redact!
    self[:canonical_email] = CheckEmailAddress.redact(self.canonical_email)
    self[:email]           = self[:canonical_email]
  end

end
