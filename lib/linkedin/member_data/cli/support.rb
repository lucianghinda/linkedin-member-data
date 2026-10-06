# frozen_string_literal: true

require "json"

module LinkedIn
  module MemberData
    class CLI
      # Bad command line: unknown command, missing argument, bad value.
      class UsageError < StandardError; end

      # Data goes to a file or stdout. Progress and errors go to stderr.
      class Output
        def initialize(stdout, stderr)
          @stdout = stdout
          @stderr = stderr
        end

        # Files get the same bytes as stdout, including the final newline.
        def write(data, path = nil)
          json = JSON.pretty_generate(data)
          path ? File.write(path, "#{json}\n") : @stdout.puts(json)
        end

        def line(text) = @stdout.puts(text)

        def error(text) = @stderr.puts(text)

        alias progress error
      end

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

        def use_token(value)
          @token = value
        end

        private

        def access_token
          value = (@token || @env[TOKEN_ENV]).to_s.strip
          raise ConfigurationError, "no access token: pass --token or set #{TOKEN_ENV}" if value.empty?

          value
        end
      end
    end
  end
end
