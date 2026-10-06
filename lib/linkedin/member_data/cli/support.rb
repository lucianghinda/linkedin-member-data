# frozen_string_literal: true

require "json"

module LinkedIn
  module MemberData
    class CLI
      # Bad command line: unknown command, missing argument, bad value.
      # @api private
      class UsageError < StandardError; end

      # Data goes to a file or stdout. Progress and errors go to stderr.
      # @api private
      class Output
        # @param stdout [IO]
        # @param stderr [IO]
        def initialize(stdout, stderr)
          @stdout = stdout
          @stderr = stderr
        end

        # Files get the same bytes as stdout, including the final newline.
        # @param data [Object] anything JSON can encode.
        # @param path [String, nil] file to write. `nil` means stdout.
        # @return [void]
        def write(data, path = nil)
          json = JSON.pretty_generate(data)
          path ? File.write(path, "#{json}\n") : @stdout.puts(json)
        end

        # Prints a line to stdout.
        # @param text [String, Array<String>]
        # @return [void]
        def line(text) = @stdout.puts(text)

        # Prints a line to stderr.
        # @param text [String]
        # @return [void]
        def error(text) = @stderr.puts(text)

        alias progress error
      end

      # What every command needs: the output and a lazy client.
      # The token is only looked up when a command asks for the client.
      # @api private
      class Context
        # Name of the environment variable that holds the token.
        # @return [String]
        TOKEN_ENV = "LINKEDIN_ACCESS_TOKEN"

        # @return [Output]
        attr_reader :output

        # @param output [Output]
        # @param env [Hash, #[]] environment.
        # @param client_factory [#call] takes a token and returns a `Client`.
        # @param token [String, nil] token from `--token`.
        def initialize(output:, env:, client_factory:, token:)
          @output = output
          @env = env
          @client_factory = client_factory
          @token = token
        end

        # The client, built on first use.
        # @return [Client]
        # @raise [ConfigurationError] when no token is set.
        def client = @client ||= @client_factory.call(access_token)

        # Replaces the token from `--token`.
        # @param value [String]
        # @return [String]
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
