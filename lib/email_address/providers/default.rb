module EmailAddress
  module Providers
    class Default
       #def initialize(address)
       #  @mailbox = mailbox
       #end

       def self.provider
         'default'
       end

       def self.tag_separator
         '+'
       end

       def self.case_sensitive_mailbox
         false
       end

       def self.max_domain_length
         253
       end

       def self.max_email_length
         254
       end

       # Letters, numbers, period (no start) 6-30chars
       def self.max_mailbox_length
         64
       end

       # Letters, numbers, period (no start) 6-30chars
       def self.user_pattern
         /\A[a-z0-9][\.\'a-z0-9]{5,29}\z/i
       end

       def self.valid?
         return false unless valid_format?
       end

       def self.valid_format?
         return false if mailbox.length > max_mailbox_length
         return false if address.length > max_email_length
         return false unless mailbox.to_s.match(user_pattern)
         true
       end

    end
  end
end
