module EmailAddress
  class Config

    # EmailAddress::Config.add_provider(:google, domain_names:["gmail.com", "googlemail.com", "google.com"])
    def self.add_provider(provider, matches={})
      @pmatch ||= []
      @pmatch << matches
    end

    # EmailAddress::Config.config do .... end
    def self.setup(&block)
      @config = Config::DSL.new(&block)
      @config.instance_eval(&block)
    end

    def self.get
      @config
    end

    class DSL
      attr_accessor :provider_matching_rules
      def add_provider(provider, matches={})
        puts provider, matches
        @provider_matching_rules ||= []
        @provider_matching_rules << {provider:provider, matches:matches}
      end
    end
  end
end


#EmailAddress::Config.setup do 
#  add_provider :google, domain_names:["gmail.com", "googlemail.com", "google.com"]
#end

#puts EmailAddress::Config.provider_matching_rules
