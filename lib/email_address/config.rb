module EmailAddress
  class Config

    @providers = {
       default: {
         email_domains: [],
         smtp_domains:  [],
         canonical_mailbox: ->(m) {m},
         tag_separator: '+',
         case_sensitive: false,
         mailbox_max_size: 64,
         valid_mailbox:  ->(m) {true},
       }
    }
    @options = {
       downcase_mailboxes: true,
    }

    class Setup
      attr_reader :providers

      def initialize
        @providers = {}
      end

      def do_block(&block)
        instance_eval(&block)
      end

      def provider(name, defn={})
        @providers[name] = defn
      end

      def option(name, value)
        @@edits[name.to_sym] = value
      end
    end

    def self.setup(&block)
      @setup ||= Setup.new
      @setup.do_block(&block) if block_given?
      @setup
    end
  end
end
