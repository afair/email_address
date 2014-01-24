module EmailAddress
  class Validator
    ##############################################################################
    # Validations -- Eventually a provider-sepecific check
    ##############################################################################
    def valid?
      return false unless @local =~ user_pattern
      return false unless provider # .valid_domain
      true
    end

    def valid_format?
      return false unless @local.match(user_pattern)
      return false unless @host.valid_format?
      true
    end
  end
end
