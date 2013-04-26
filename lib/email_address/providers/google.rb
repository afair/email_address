module EmailAddress
  module Providers
    class Google < Default
       def account
         account.gsub(/\./. '')
       end

       def provider
         'google'
       end

       def tag_separator
         '+'
       end

       def case_sensitive_mailbox
         false
       end

       # Letters, numbers, period (no start) 6-30chars
       def user_pattern
         /\A[a-z0-9][\.a-z0-9]{5,29}\z/i
       end

    end
  end
end
