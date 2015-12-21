module EmailAddress
  class Config
    @options = {
       downcase_mailboxes: true,
       check_dns:          true,
       #default_format:     EmailAddress::CHECK_CONVENTIONAL_SYNTAX,
    }

    @providers = {
       default: {
         domains:           [],
         exchangers:        [],
         tag_separator:     '+',
         case_sensitive:    false,
         address_size:      3..254,
         local_size:        1..64,
         domain_size:       1..253,
         mailbox_size:      1..64,
         mailbox_unicode:   false,
         canonical_mailbox: ->(m) {m},
         valid_mailbox:     nil,  # :legible, :rfc, ->(m) {true}
       },
       aol: {
         registration_names: %w(aol compuserve netscape aim cs)
       },
       google: {
         domains:           %w(gmail.com googlemail.com),
         exchangers:        %w(google.com),
         local_size:        5..64,
         canonical_mailbox: ->(m) {m.gsub('.','')},
         #valid_mailbox:    ->(local) { local.mailbox =~ /\A[a-z0-9][\.a-z0-9]{5,29}\z/i},
       },
       msn: {
         valid_mailbox:    ->(m) { m =~ /\A[a-z0-9][\.\-a-z0-9]{5,29}\z/i},
       },
       yahoo: {
         domains:          %w(yahoo ymail rocketmail),
         exchangers:       %w(yahoodns yahoo-inc),
       },
    }

    def self.providers
      @providers
    end

    #def provider(name, defn={})
    #  EmailAddress::Config.providers[name] = defn
    #end

    def self.options
      @options
    end

    def self.provider(name)
      @providers[:default].merge(@providers.fetch(name) { Hash.new })
    end

    class Setup
      attr_reader :providers

      def initialize
        @providers = {}
      end

      def do_block(&block)
        instance_eval(&block)
      end

      def provider(name, defn={})
        EmailAddress::Config.providers[name] = defn
      end

      def option(name, value)
        EmailAddress::Config.options[name.to_sym] = value
      end
    end

    def self.setup(&block)
      @setup ||= Setup.new
      @setup.do_block(&block) if block_given?
      @setup
    end
  end
end
