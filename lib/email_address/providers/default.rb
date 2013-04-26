module EmailAddress
  module Providers
    class Default
       def initialize(address)
         @mailbox = mailbox
       end

       def account(mailbox)
         mailbox
       end

       def provider
         'default'
       end

       def tag_separator
         '+'
       end

       def case_sensitive_mailbox
         false
       end

       def max_domain_length
         253
       end

       def max_email_length
         254
       end

       # Letters, numbers, period (no start) 6-30chars
       def max_mailbox_length
         64
       end

       # Letters, numbers, period (no start) 6-30chars
       def user_pattern
         /\A[a-z0-9][\.\'a-z0-9]{5,29}\z/i
       end

       def valid?
         return false unless valid_format?
       end

       def valid_format?
         return false if mailbox.length > max_mailbox_length
         return false if address.length > max_email_length
         return false unless mailbox.to_s.match(user_pattern)
         true
       end

    end
  end
end
