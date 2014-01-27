require 'singleton'

module EmailAddress
  class Config

    class Setup
      attr_reader :providers

      def initialize
        @providers = {}
      end

      def do_block(&block)
        instance_eval(&block)
      end

      def add_provider(name, defn={})
        @providers[name] = defn
      end
    end

    def self.setup(&block)
      @setup ||= Setup.new
      @setup.do_block(&block) if block_given?
      @setup
    end
  end
end
