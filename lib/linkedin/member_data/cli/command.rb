# frozen_string_literal: true

require "optparse"

module LinkedIn
  module MemberData
    class CLI
      # Base for commands. A command parses its own options, then runs.
      # `run` returns the exit code.
      # @api private
      class Command
        # Option specs for OptionParser#on. Subclasses override.
        # @return [Array<Array>]
        OPTIONS = [].freeze
        # Positional arguments the command accepts.
        # @return [Integer]
        MAX_ARGUMENTS = 0

        # @param context [Context]
        # @param argv [Array<String>] arguments after the command name. Options are removed from it.
        def initialize(context, argv)
          @context = context
          @argv = argv
          @options = {}
        end

        # Parses options, checks arguments and executes.
        # @return [Integer] exit code.
        # @raise [UsageError] on bad arguments.
        def run
          parser.parse!(argv, into: options)
          context.use_token(options[:token]) if options.key?(:token)
          check_arguments
          execute
        end

        private

        attr_reader :context, :argv, :options

        def check_arguments
          extra = argv.drop(self.class::MAX_ARGUMENTS)
          raise UsageError, "unexpected argument: #{extra.first}" unless extra.empty?
        end

        def output = context.output

        def client = context.client

        def parser
          parser = OptionParser.new("Usage: linkedin-member-data COMMAND [options]")
          parser.on("--token TOKEN")
          self.class::OPTIONS.each { |spec| parser.on(*spec) }
          parser
        end
      end
    end
  end
end
