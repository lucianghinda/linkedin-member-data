# frozen_string_literal: true

require "optparse"

require_relative "cli/global_options"
require_relative "cli/support"
require_relative "cli/since_parser"
require_relative "cli/command"
require_relative "cli/simple_commands"
require_relative "cli/snapshot_command"
require_relative "cli/changelog_command"

module LinkedIn
  module MemberData
    # Command line entry point. Data goes to stdout or files, progress and
    # errors go to stderr. Exit codes: 0 ok, 1 API error, 2 usage error.
    class CLI
      COMMANDS = {
        "snapshot" => SnapshotCommand,
        "changelog" => ChangelogCommand,
        "domains" => DomainsCommand,
        "auth" => AuthCommand,
        "version" => VersionCommand
      }.freeze

      DEFAULT_CLIENT_FACTORY = ->(token) { Client.new(access_token: token) }

      USAGE = <<~TEXT
        Usage: linkedin-member-data [--token TOKEN] COMMAND [options]

        Commands:
          snapshot DOMAIN [--out FILE]        Download one snapshot domain as a JSON array
          snapshot --all --out-dir DIR        Download every domain, one <DOMAIN>.json per domain
          changelog [--since DATE] [--count N] [--out FILE]
                                              Download changelog events (last 28 days)
          domains                             List snapshot domains
          auth                                Show authorization status as JSON
          version                             Print the gem version

        The token comes from --token or the LINKEDIN_ACCESS_TOKEN environment variable.
      TEXT

      def initialize(argv, stdout: $stdout, stderr: $stderr, env: ENV, client_factory: DEFAULT_CLIENT_FACTORY)
        @argv = argv.dup
        @output = Output.new(stdout, stderr)
        @env = env
        @client_factory = client_factory
      end

      def run
        handling_errors { start }
      end

      private

      def start
        options = GlobalOptions.parse(@argv)
        options[:help] ? help : dispatch(options[:token])
      end

      def handling_errors
        yield
      rescue UsageError, OptionParser::ParseError, ConfigurationError => error
        usage_failure(error)
      rescue Error, SystemCallError => error
        failure(error)
      end

      def dispatch(token)
        name = @argv.shift
        raise UsageError, "missing command" if name.nil?

        COMMANDS.fetch(name) { raise UsageError, "unknown command: #{name}" }.new(context(token), @argv).run
      end

      def context(token)
        Context.new(output: @output, env: @env, client_factory: @client_factory, token: token)
      end

      def help
        @output.line(USAGE)
        0
      end

      def failure(error)
        @output.error("error: #{error.message}")
        1
      end

      def usage_failure(error)
        @output.error("error: #{error.message}")
        @output.error(USAGE)
        2
      end
    end
  end
end
