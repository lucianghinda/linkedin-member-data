# frozen_string_literal: true

module LinkedIn
  module MemberData
    class CLI
      # What every command needs: the output and a lazy client.
      # The token is only looked up when a command asks for the client.
      class Context
        TOKEN_ENV = "LINKEDIN_ACCESS_TOKEN"

        attr_reader :output

        def initialize(output:, env:, client_factory:, token:)
          @output = output
          @env = env
          @client_factory = client_factory
          @token = token
        end

        def client = @client ||= @client_factory.call(access_token)

        private

        def access_token
          value = @token || @env[TOKEN_ENV]
          raise ConfigurationError, "no access token: pass --token or set #{TOKEN_ENV}" if value.to_s.empty?

          value
        end
      end
    end
  end
end
