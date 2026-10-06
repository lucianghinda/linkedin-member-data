# frozen_string_literal: true

module LinkedIn
  module MemberData
    class CLI
      # Prints the gem version.
      class VersionCommand < Command
        private

        def execute
          output.line(VERSION)
          0
        end
      end

      # Prints one snapshot domain per line. Needs no token.
      class DomainsCommand < Command
        private

        def execute
          output.line(Domains::ALL)
          0
        end
      end

      # Prints the authorization of the token as JSON.
      class AuthCommand < Command
        private

        def execute
          authorization = client.authorization
          return missing if authorization.nil?

          output.write(authorization.raw)
          0
        end

        def missing
          output.error("No authorization found for this token")
          1
        end
      end
    end
  end
end
