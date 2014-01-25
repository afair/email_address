module EmailAddress
  module Providers
    class Google < Default

       def self.provider
         'google'
       end

       # Letters, numbers, period (no start) 6-30chars
       def self.user_pattern
         /\A[a-z0-9][\.a-z0-9]{5,29}\z/i
       end

       def self.canonical_mailbox(mailbox)
         mailbox.gsub(/\./, '')
       end

       def self.email_domains
         %w(gmail.com)
       end

       def self.mx_domains
         %w(google.com)
       end

    end
  end
end
